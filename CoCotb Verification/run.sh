cd /home/runner
export PATH=/usr/bin:/bin:/tool/pandora64/bin:/usr/local/bin
export EDATOOL=icarus
export HOME=/home/runner
chmod +x run.bash; sed -i -e 's/\r//g' run.bash; ./run.bash  ; echo 'Creating result.zip...' && zip -r /tmp/tmp_zip_file_123play.zip . && mv /tmp/tmp_zip_file_123play.zip result.zip