command -v nodemon >/dev/null || npm i nodemon -g
[[ ! -e .v/bin/activate ]] && python3 -m venv .v
source .v/bin/activate
pip install simplejson
#pip install psutil bcc loguru
