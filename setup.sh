export PATH=$PATH:$(pwd)/bin:~/.npm-global/bin
for nm in nodemon tailol; do
  (set +e;command -v $nm >/dev/null || npm i $nm -g)
done
[[ ! -e .v/bin/activate ]] && python3 -m venv .v
(set +e; pip3 install simplejson >/dev/null 2>&1)
source .v/bin/activate
pip install simplejson
#pip install psutil bcc loguru
