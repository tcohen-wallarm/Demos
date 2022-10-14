echo -e '\033[48;5;166m => sqli & xss attack\033[0m'
(set -x; curl http://localhost:8080/?id='%27or+1=1--a-%3Cscript%3Eprompt(1)%3C/script%3E%27')
