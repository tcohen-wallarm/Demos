usage ()
{
    echo -e "\033[48:5:166:0mUsage: \033[0m"
    echo "$0 http://localhost       - Run gowaftest on endpoint"
    echo "$0 http://localhost -s    - Skip target endpoint WAF verification"
    exit 0

}


exit_on_error() {
    exit_code=$1
    last_command=${@:2}
    if [ $exit_code -ne 0 ]; then
        >&2 echo "\"${last_command}\" command failed with exit code ${exit_code}."
        exit $exit_code
    fi
}

if [ -z $1 ]; then
    usage
fi

skip=""

if [ ! -z $2 ]; then
    if [ $2 == "-s" ]; then
    skip="--blockStatusCode 200"
    else
        usage
    fi
fi


 if [ -f /.dockerenv ]; then
    export GO111MODULE=on

    if [ ! -d gotestwaf ]; then
        git clone https://github.com/wallarm/gotestwaf.git
    fi
    
    cd gotestwaf

    (set -x; go build -o gotestwaf -mod vendor ./cmd/main.go)
    exit_on_error $?
    (set -x; ./gotestwaf wallarm/gotestwaf --reportPath ../reports/ $skip --url "$1")
    # go run ./cmd --blockStatusCode 200 --url=https://cafe.example.com:31246/coffee

 else
    (set -x; docker run --network="host" -v ${PWD}/reports:/go/src/gotestwaf/reports wallarm/gotestwaf $skip --url "$1")
fi

