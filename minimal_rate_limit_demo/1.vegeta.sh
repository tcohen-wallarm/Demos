
#go get -u github.com/tsenart/vegeta
echo -e '\033[48;5;166m => vegeta attack rate 10requests/1s \033[0m'
(set -x; echo "GET http://localhost:8080/index.html" | vegeta attack -duration=10s -rate=10 | vegeta report)

read -n 1 -s -r -p "<Press any key to continue>"
printf "\n"

echo -e '\033[48;5;166m => vegeta attack rate 5requests/1s \033[0m'
(set -x; echo "GET http://localhost:8080/index.html" | vegeta attack -duration=10s -rate=5 | vegeta report)

