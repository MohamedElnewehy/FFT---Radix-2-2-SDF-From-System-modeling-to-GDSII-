import os
import sys

# --- HACK TO INSTALL NUMPY ON EDA PLAYGROUND ---
try:
    import numpy as np
except ImportError:
    print("NumPy not found. Installing it on the fly...")
    # Python 3.6 requires numpy version < 1.20
    os.system("python3 -m pip install 'numpy<1.20' --user")
    
    # Add the local user package directory to Python's path
    import site
    sys.path.append(site.getusersitepackages())
    import numpy as np
    print("NumPy successfully installed!")
# -----------------------------------------------

import random
import cmath
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

# ... [REST OF YOUR TESTBENCH CODE using np.fft.fft(x_frames[f])] ...

N = 16
FRAC = 10                       # Q1.10 in, Q3.10 out (both scaled by 1024)
NUM_FRAMES = int(os.environ.get("NUM_FRAMES", "500"))
MIN_SQNR_DB = float(os.environ.get("MIN_SQNR_DB", "30"))
SEED = os.environ.get("SEED")   # set for reproducible runs, e.g. SEED=1234
if SEED is not None:
    random.seed(int(SEED))

# RTL emits bins in bit-reversed order
BIT_REV = [int(f"{k:04b}"[::-1], 2) for k in range(N)]

def to_signed(val, bits):
    val &= (1 << bits) - 1
    return val - (1 << bits) if val & (1 << (bits - 1)) else val

def fmt_cplx_list(vals):
    return "[" + ", ".join(f"{v.real:+.3f}{v.imag:+.3f}j" for v in vals) + "]"

def value_bucket(v):
    if v <= -256: return "neg_max"
    if v < 0:     return "neg_mid"
    if v == 0:    return "zero"
    if v < 256:   return "pos_mid"
    return "pos_max"

def sqnr_bucket(db):
    if db < 20: return "<20dB"
    if db < 30: return "20-30dB"
    if db < 40: return "30-40dB"
    return ">40dB"

def directed_corner_frames():
    """
    Hand-crafted frames that guarantee every value-bucket and corner
    coverpoint gets hit at least once, instead of relying on random luck.
    Each entry is (re_list, im_list), 16 samples each.
    """
    frames = []

    # all samples at max positive (511,511) -> re_max, im_max, pos_max bucket
    frames.append(([511] * N, [511] * N))
    # all samples at max negative (-511,-511) -> re_min, im_min, neg_max bucket
    frames.append(([-511] * N, [-511] * N))
    # all samples at zero -> re_zero, im_zero, zero bucket
    frames.append(([0] * N, [0] * N))
    # re at max, im at min, and vice versa (cross corners in one frame)
    frames.append(([511] * N, [-511] * N))
    frames.append(([-511] * N, [511] * N))
    # alternating +/-511 across the frame, re and im out of phase
    frames.append(([511 if i % 2 == 0 else -511 for i in range(N)],
                   [-511 if i % 2 == 0 else 511 for i in range(N)]))

    return frames

@cocotb.test()
async def test_fft_random(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # reset
    dut.rst_n.value = 0
    dut.x_valid.value = 0
    dut.x_start.value = 0
    dut.x_done.value = 0
    dut.x_in.value = 0
    for _ in range(4):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # background: collect every y_valid sample
    y_samples = []

    async def collect():
        while True:
            await RisingEdge(dut.clk)
            if dut.y_valid.value:
                raw = int(dut.y_out.value)
                re = to_signed((raw >> 14) & 0x3FFF, 14)
                im = to_signed(raw & 0x3FFF, 14)
                y_samples.append(complex(re, im) / (1 << FRAC))

    cocotb.start_soon(collect())

    # ---------------- functional coverage tracking ----------------
    re_bins = {"neg_max": 0, "neg_mid": 0, "zero": 0, "pos_mid": 0, "pos_max": 0}
    im_bins = {"neg_max": 0, "neg_mid": 0, "zero": 0, "pos_mid": 0, "pos_max": 0}
    corners = {"re_min": False, "re_max": False, "re_zero": False,
               "im_min": False, "im_max": False, "im_zero": False}
    sqnr_bins = {"<20dB": 0, "20-30dB": 0, "30-40dB": 0, ">40dB": 0}

    directed = directed_corner_frames()
    total_frames = len(directed) + NUM_FRAMES

    dut._log.info("Driving %d directed + %d random frames = %d total (seed=%s)...",
                  len(directed), NUM_FRAMES, total_frames, SEED if SEED else "random/unfixed")

    # drive directed frames first (guarantees corner-case coverage), then
    # random frames, keeping the exact inputs for the reference DFT
    x_frames = []
    progress_step = max(1, total_frames // 10)
    for f in range(total_frames):
        if f % progress_step == 0:
            dut._log.info("   ... %d/%d frames driven", f, total_frames)

        if f < len(directed):
            re, im = directed[f]
        else:
            re = [random.randint(-511, 511) for _ in range(N)]
            im = [random.randint(-511, 511) for _ in range(N)]
        x_frames.append([complex(re[i], im[i]) / (1 << FRAC) for i in range(N)])

        for i in range(N):
            re_bins[value_bucket(re[i])] += 1
            im_bins[value_bucket(im[i])] += 1
            if re[i] == -511: corners["re_min"] = True
            if re[i] == 511:  corners["re_max"] = True
            if re[i] == 0:    corners["re_zero"] = True
            if im[i] == -511: corners["im_min"] = True
            if im[i] == 511:  corners["im_max"] = True
            if im[i] == 0:    corners["im_zero"] = True

            await RisingEdge(dut.clk)
            dut.x_valid.value = 1
            dut.x_start.value = (i == 0)
            dut.x_done.value = (i == N - 1)
            dut.x_in.value = ((re[i] & 0x7FF) << 11) | (im[i] & 0x7FF)

    await RisingEdge(dut.clk)
    dut.x_valid.value = 0
    dut.x_start.value = 0
    dut.x_done.value = 0

    dut._log.info("All %d frames driven. Flushing pipeline...", total_frames)

    # flush: wait for every sample to come out (latency-agnostic)
    total = total_frames * N
    for _ in range(total * 20 + 1000):
        if len(y_samples) >= total:
            break
        await RisingEdge(dut.clk)
    await Timer(1, units="ns")

    dut._log.info("Flush complete: collected %d/%d output samples.", len(y_samples), total)
    assert len(y_samples) == total, f"got {len(y_samples)} outputs, expected {total}"

    # ---------------- per-transaction compare + report ----------------
    pass_count = 0
    fail_count = 0
    sqnr_list = []
    global_max_err = 0.0

    # Tolerance for fixed-point quantization noise when expected output is 0.
    ZERO_TOLERANCE = 0.05

    for f in range(total_frames):
        y_rtl_raw = y_samples[f * N:(f + 1) * N]
        y_rtl = [y_rtl_raw[BIT_REV[k]] for k in range(N)]  # undo bit-reversal
        
        # ---> CHANGED: Using NumPy's built-in FFT instead of custom O(N^2) dft <---
        y_ref = np.fft.fft(x_frames[f])

        p_signal = sum(abs(v) ** 2 for v in y_ref)
        p_noise = sum(abs(y_ref[k] - y_rtl[k]) ** 2 for k in range(N))
        max_err = max(abs(y_ref[k] - y_rtl[k]) for k in range(N))
        global_max_err = max(global_max_err, max_err)

        if p_noise == 0:
            sqnr_db = float("inf")          # exact match, no error at all
        elif p_signal == 0:
            # Expected exactly zero but got fixed-point noise.
            if max_err <= ZERO_TOLERANCE:
                sqnr_db = 100.0             # Dummy high SQNR to force a PASS
            else:
                sqnr_db = -999.0            # Error too high -> fail
        else:
            sqnr_db = 10 * cmath.log10(p_signal / p_noise).real

        sqnr_list.append(sqnr_db)
        sqnr_bins[sqnr_bucket(sqnr_db)] += 1

        tag = "DIRECTED" if f < len(directed) else " RANDOM "
        status = "PASS" if sqnr_db >= MIN_SQNR_DB else "FAIL"
        if status == "PASS":
            pass_count += 1
            dut._log.info("Transaction %d/%d [%0s] : PASS | SQNR=%.2f dB | MaxErr=%.6f",
                           f + 1, total_frames, tag, sqnr_db, max_err)
        else:
            fail_count += 1
            dut._log.error("Transaction %d/%d [%0s] : FAIL | SQNR=%.2f dB | MaxErr=%.6f",
                            f + 1, total_frames, tag, sqnr_db, max_err)
            dut._log.error("  Expected : %s", fmt_cplx_list(y_ref))
            dut._log.error("  Actual   : %s", fmt_cplx_list(y_rtl))

    mean_sqnr = sum(sqnr_list) / len(sqnr_list) if sqnr_list else float("inf")

    # ---------------- functional coverage report ----------------
    missing = [k for k, v in re_bins.items() if v == 0] + \
              [k for k, v in im_bins.items() if v == 0] + \
              [k for k, v in corners.items() if not v]

    re_hit = sum(1 for v in re_bins.values() if v > 0)
    im_hit = sum(1 for v in im_bins.values() if v > 0)
    corner_hit = sum(1 for v in corners.values() if v)
    total_points = len(re_bins) + len(im_bins) + len(corners)
    total_hit = re_hit + im_hit + corner_hit
    cov_pct = 100.0 * total_hit / total_points

    dut._log.info("=" * 90)
    dut._log.info("FUNCTIONAL COVERAGE REPORT")
    dut._log.info("=" * 90)
    dut._log.info("Input RE value bins : %s", re_bins)
    dut._log.info("Input IM value bins : %s", im_bins)
    dut._log.info("Corner cases hit    : %s", corners)
    dut._log.info("SQNR distribution   : %s", sqnr_bins)
    dut._log.info("RE bin coverage     : %d/%d (%.1f%%)", re_hit, len(re_bins), 100.0 * re_hit / len(re_bins))
    dut._log.info("IM bin coverage     : %d/%d (%.1f%%)", im_hit, len(im_bins), 100.0 * im_hit / len(im_bins))
    dut._log.info("Corner coverage     : %d/%d (%.1f%%)", corner_hit, len(corners), 100.0 * corner_hit / len(corners))
    dut._log.info("Overall coverage    : %d/%d (%.1f%%)", total_hit, total_points, cov_pct)
    if missing:
        dut._log.info("MISSING coverpoints : %s", missing)
    dut._log.info("=" * 90)

    # ---------------- final report ----------------
    dut._log.info("FINAL REPORT")
    dut._log.info("=" * 90)
    dut._log.info("Total transactions : %d (%d directed + %d random)", total_frames, len(directed), NUM_FRAMES)
    dut._log.info("Passed             : %d", pass_count)
    dut._log.info("Failed             : %d", fail_count)
    dut._log.info("Mean SQNR          : %.2f dB", mean_sqnr)
    dut._log.info("Worst-case SQNR    : %.2f dB", min(sqnr_list) if sqnr_list else float("inf"))
    dut._log.info("Max Abs Error      : %.6f", global_max_err)
    dut._log.info("Functional Coverage: %.1f%%", cov_pct)
    dut._log.info("Overall Result     : %s", "PASS" if fail_count == 0 else "FAIL")
    dut._log.info("=" * 90)

    assert fail_count == 0, f"{fail_count}/{total_frames} transactions failed (mean SQNR {mean_sqnr:.2f} dB)"