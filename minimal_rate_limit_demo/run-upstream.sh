#!/bin/env bash
echo -e '\033[48;5;166m => Starting test upstream\033[0m'
docker run -p80:80 --rm --name nginx nginx
