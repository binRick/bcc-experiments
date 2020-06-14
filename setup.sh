export PATH=$PATH:$(pwd)/bin
command -v nodemon >/dev/null || npm i nodemon -g
[[ ! -e .v/bin/activate ]] && python3 -m venv .v
(set +e; pip3 install simplejson >/dev/null 2>&1)
source .v/bin/activate
pip install simplejson
#pip install psutil bcc loguru
