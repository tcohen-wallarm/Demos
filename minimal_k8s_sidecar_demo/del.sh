#!/bin/env bash
echo -e '\033[48;5;166m => Deleting myapp and wallarm sidecar \033[0m'
(set -x; helm uninstall wallarm)
