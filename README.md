# Radix-2² Single-path Delay Feedback (R2²SDF) Pipeline FFT Processor

A from-scratch implementation of a **16-point, real-time pipeline FFT processor**, following the
Radix-2² Single-path Delay Feedback (R2²SDF) architecture proposed by:

> S. He and M. Torkelson, **"A New Approach to Pipeline FFT Processor,"**
> *Proceedings of IPPS'96*, pp. 766–770, 1996.

The project goes through the full flow: algorithm derivation → floating-point MATLAB
model → fixed-point MATLAB model (Fixed-Point Designer methodology) → cycle-accurate
Verilog RTL → RTL verification against a golden reference.

---

## 1. Why Radix-2²?

A classic trade-off exists between radix-2 and radix-4 pipeline FFTs:

| | Radix-2 | Radix-4 | **Radix-2²** |
|---|---|---|---|
| Butterfly complexity | Simple (2-point) | Complex (4-point, ≥8 adders) | **Simple (2-point)** |
| Non-trivial multipliers | `log₂N - 2` (more stages) | `log₄N - 1` (fewer, larger stages) | **`log₄N - 1`** (same as radix-4) |
| Multiplier utilization | 50% | 25–75% | 75% |

Radix-2² achieves the **same low multiplier count as radix-4**, while keeping the
**simple butterfly structure of radix-2** — the best of both worlds. This is done by
decomposing the twiddle-factor multiplication *inside* the divide-and-conquer step
(see Section III of the paper), producing a signal flow graph where every other stage
uses only a **trivial ±j rotation** (real/imag swap + sign flip — no real multiplier)
instead of a full complex multiply.

For `N = 16`, this collapses to:

```
x(n) → [BF2I, SR=8] → [BF2II, SR=4] → ⊗ W1(n) → [BF2I, SR=2] → [BF2II, SR=1] → X(k)
```

with only **one** full complex multiplier (`log₄16 - 1 = 1`) and **N-1 = 15** complex
registers total — the minimal hardware requirement among all classic pipeline FFT
architectures (R2MDC, R2SDF, R4SDF, R4MDC, R4SDC) compared in the paper's Table 1.

---

## 2. Repository structure

```
├── matlab/
│   ├── radix22_dif_fft.m         Step 1: pure algorithm (recursive, whole-vector)
│   ├── test_radix22_fft.m        Validates Step 1 against MATLAB's built-in fft()
│   ├── sdf_stage.m               Generic cycle-accurate SDF butterfly stage
│   ├── r22sdf_pipeline.m         Step 2: cycle-accurate pipeline model (1 sample/clk)
│   ├── test_r22sdf_pipeline.m    Validates Step 2 against fft() with bit-reversal
│   ├── FFT_2_2.m                 Step 3-6: fixed-point algorithmic model (%#codegen)
│   ├── FFT_2_2_types.m           Types table (double / single / Test_1..4 fixed-point)
│   ├── Instrumentation.m         buildInstrumentedMex driver
│   └── top.m                     Monte-Carlo SQNR / error-ratio sweep (100 seeds)
│
├── rtl/
│   ├── BF_1.v                    Radix-2 butterfly (plain add/sub, load/compute phases)
│   ├── BF_2.v                    Radix-2 butterfly + trivial ±j rotation
│   ├── shift_reg.v               Generic parameterized shift register
│   ├── synch_counter.v           4-bit synchronizing counter (sync_counter module)
│   ├── twiddle_gen.v             Twiddle-factor address generator + ROM (7 stored values)
│   ├── cplx_multiplier.v         3-multiplier complex multiplier (Algorithm 6.10),
│   │                             pipelined (1 extra clock) to break the critical path
│   ├── control_unit.v            Generic LATENCY-deep valid/start/done delay + pipe_en
│   └── FFT_2_2_top.v             Top-level: wires all of the above together
│
└── tb/
    ├── tb_cplx_multiplier.v       Directed unit test for the multiplier
    ├── tb_FFT_2_2_top.v           Single-frame integration test vs. golden reference
    ├── golden_vectors.vh          Auto-generated (Python) fixed-point golden data
    └── tb_random.sv               Multi-frame (1000x) randomized regression test
```

---

## 3. Design flow

### 3.1 Algorithm verification (floating point)
`radix22_dif_fft.m` implements the algorithm exactly as derived in Section III of the
paper (eqn. 3–6): each recursion level splits the input into 4 quarters, combines them
with two trivial butterfly stages (**BF I**: ±, **BF II**: trivial `(-j)^(k1+2k2)`
factor), applies one real twiddle multiply per branch, then recurses. Verified against
`fft()` for N = 16, 64, 256 — error at floating-point machine precision (~1e-15).

### 3.2 Cycle-accurate pipeline model (floating point)
`r22sdf_pipeline.m` re-implements the same algorithm, but **one sample per clock**,
with real shift-register state carried across clocks — i.e. it behaves exactly like
the RTL will, including:
- a single 4-bit synchronizing counter driving every mux/commutator/twiddle-ROM select
- the exact clock cycles at which each `BF2II` block must apply the trivial `-j`
  rotation
- the exact (non-obvious) twiddle-branch addressing order
- **N-1 = 15** clock latency before the first valid output, then continuous
  bit-reversed output, one sample per clock, forever

Verified bit-exact (≈1e-15 error) against `fft()` across multiple random test frames.

### 3.3 Fixed-point design (Analog Devices' 7-step Fixed-Point Designer methodology)
1. **Isolate Core Algorithm** — separate `FFT_2_2.m` from test code
2. **Prepare for Instrumentation** — `%#codegen`, Code Generation Readiness check
3. **Fixed-Point Designer** — `buildInstrumentedMex` + `showInstrumentationResults`
4. **Create Types Table** — `FFT_2_2_types.m` (`double` / `single` / fixed-point cases)
5. **Finalize Design Parameters** — N = 16 fixed
6. **Add Fixed-Point Types to the Table** — integer widths from `-proposeFL` /
   `Sim Min`/`Sim Max`, fractional widths chosen via **SQNR** sweep across 4 candidate
   word lengths (`Test_1`…`Test_4`)
7. **Optimize Algorithm** — selected configuration: **min SQNR = 56 dB** across
   100 Monte-Carlo seeds

**Final bit-width table** (word length WL = real width = imag width; total register
width = 2×WL):

| Signal | WL | Int bits | Frac bits |
|---|---|---|---|
| `x` (input) | 16 | 1 | 15 |
| `bf1_out` / SR8 | 12 | 2 | 10 |
| `bf2_out` / SR4 | 14 | 3 | 11 |
| `twiddle_factor` | 12 | 1 | 11 |
| `complex_mult_out` | 14 | 3 | 11 |
| `bf3_out` / SR2 | 14 | 4 | 10 |
| `bf4_out` / SR1 | 14 | 4 | 10 |
| `y` (output) | 16 | 4 | 12 |

### 3.4 RTL implementation
Each MATLAB signal/operation maps directly onto a Verilog module:

- **`BF_1` / `BF_2`** implement the SDF butterfly's load/compute phase behaviour:
  during *load*, the incoming sample is stored and the register's oldest value passes
  straight through; during *compute*, `sum = old + new` is driven out immediately and
  `diff = old - new` is written back for later. `BF_2` additionally applies the
  trivial `-j` rotation (`real ↔ imag` swap + sign flip, **no real multiplier**) when
  its `rot_sel` control input is active.
- **`cplx_multiplier`** implements the **3-multiplier / efficient algorithm**
  (`E = X-Y`, `Z = C·E`, `R = (C-S)·Y + Z`, `I = (C+S)·X - Z`), saving one real
  multiplier at the cost of one extra addition. A pipeline register was added between
  the 3 multiplications and the final add/subtract stage to shorten the critical
  path; downstream control bits (`b1_d`, `b0_d`) are delayed by one clock to stay
  aligned with the now 1-cycle-later data.
- **`twiddle_gen`** stores only the **7 distinct values** actually needed
  (`W_N^0 … W_N^9`, addresses `0,1,2,3,4,6,9`), including the classic **W⁰=1
  representability edge case** (1.0 is not exactly representable in signed Q1.11;
  the ROM stores the nearest representable value instead).
- **`control_unit`** is a generic `LATENCY`-deep shift-register-based valid/start/done
  delay line, with `pipe_en = valid_in | (any bit of valid_pipe)` so the pipeline
  keeps draining on its own after the input stream ends, without needing external
  padding cycles.
- **`FFT_2_2_top`** wires everything together exactly as in the paper's Fig. 4/5.

---

## 4. How to run

### MATLAB
```matlab
% Step 1: pure algorithm vs. fft()
test_radix22_fft

% Step 2: cycle-accurate floating-point pipeline vs. fft()
test_r22sdf_pipeline

% Fixed-point Monte-Carlo SQNR sweep (requires Fixed-Point Designer)
top
```

### RTL (Icarus Verilog)
```bash
iverilog -g2012 -o sim.out BF_1.v BF_2.v shift_reg.v synch_counter.v \
    twiddle_gen.v cplx_multiplier.v control_unit.v FFT_2_2_top.v tb_FFT_2_2_top.v
vvp sim.out
```

### RTL (Vivado)
Add all `rtl/*.v` files as design sources and the relevant `tb/*.v(.sv)` as a
simulation source (plus any `.vh` golden-vector include file), then
`launch_simulation`.

---

## 5. Verification results

- **Single-frame integration test** (`tb_FFT_2_2_top.v`): all 16 output samples match
  a Python-computed golden fixed-point reference to within quantization noise
  (max error ≤ 10 LSBs at Q4.12, i.e. < 0.1% of full scale).
- **Back-to-back, multi-frame streaming test** (`tb_random.sv`, 3–1000 frames): FFT
  output for every frame matches its golden reference with max error ≈ 0.0066
  (consistent with the ~56 dB SQNR measured in MATLAB) — confirms the architecture
  correctly sustains continuous, non-stopping streaming across frame boundaries.

---

## 6. Known issues / in progress

- **Valid-sample count mismatch during stream flush**: in the extended
  multi-frame randomized test, `y_valid` currently pulses **one fewer** time than
  `x_valid` over a full run (e.g. 47 vs. 48 for a 3-frame test) — one output sample
  is being dropped somewhere in the `control_unit` / `pipe_en` interaction during
  the tail-end flush after the input stream stops. Under active debugging via
  cycle-by-cycle signal tracing; not yet root-caused. **Does not affect** the
  steady-state, continuously-streaming portion of the pipeline (verified correct
  above) — only the very last sample(s) at stream shutdown.

---

## 7. Bugs found & fixed during development

- **`BF_2` trivial rotation sign error**: an early version applied `-j` where `+j`
  was required (comment vs. code mismatch), causing correct results only in the
  first couple of output samples and increasingly wrong results afterward (the
  error compounds because the wrong value gets fed back into the register). Found
  by comparing RTL simulation output against a golden reference — a reminder that
  hand-derived sign conventions in complex-rotation hardware are easy to get
  backwards and should always be checked against simulation, not just algebra.
- **Testbench `x_valid` drop mid-frame**: an early testbench deasserted `x_valid`
  right after the 16 real input samples of a frame, before the pipeline had a
  chance to flush the second half of its internal state — since `x_valid` gates
  *every* register and the counter, this froze the whole pipeline mid-computation.

---

## 8. References

1. S. He, M. Torkelson, *"A New Approach to Pipeline FFT Processor,"* Proc. IPPS'96,
   pp. 766–770.
2. Analog Devices, *Fixed-Point Designer workflow* (Isolate → Instrument → Types
   Table → Finalize Parameters → Add FxPt Types → Optimize).-
