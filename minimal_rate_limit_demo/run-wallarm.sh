#!/bin/env bash
echo -e '\033[48;5;166m => Starting Wallarm SSL Proxy\033[0m'
docker run --rm --name wallarm -v $PWD/default.conf:/etc/nginx/sites-enabled/default -e DEPLOY_USER=$WC_DEPLOY_USER -e DEPLOY_PASSWORD=$WC_DEPLOY_PASSWORD -e NGINX_BACKEND='localhost' -e WALLARM_API_HOST='us1.api.wallarm.com' -e TARANTOOL_MEMORY_GB=16 -p 8080:8080 wallarm/node:3.2.0-1 
