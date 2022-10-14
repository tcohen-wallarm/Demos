#!/bin/env bash


echo -e '\033[48;5;166m => Installing myapp and wallarm sidecar \033[0m'
(set -x; helm install -f sidecar-chart/wallarm-sidecar/values.yaml --set wallarm.deploy_username=$WC_DEPLOY_USER,wallarm.deploy_password=$WC_DEPLOY_PASSWORD wallarm sidecar-chart/wallarm-sidecar/)
