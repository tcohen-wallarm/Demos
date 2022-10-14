#!/bin/env bash
echo -e '\033[48;5;166m => Updating myapp and wallarm sidecar \033[0m'

(set -x; helm upgrade -f sidecar-chart/wallarm-sidecar/values.yaml wallarm sidecar-chart/wallarm-sidecar/)
