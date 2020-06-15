source setup_path.sh
for nm in nodemon tailol; do
  (set +e;command -v $nm >/dev/null || npm i $nm -g)
done
[[ ! -e .v/bin/activate ]] && python3 -m venv .v
#(set +e; pip3 install simplejson >/dev/null 2>&1)
source .v/bin/activate
pip install tmuxp psutil bcc loguru  simplejson
