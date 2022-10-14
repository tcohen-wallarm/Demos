#!/bin/env bash
echo -e '\033[48;5;166m => Testing wallarm sidecar with sqli and xss attacks \033[0m'

#NODE_IP=$(kubectl get nodes --selector=node-role.kubernetes.io/master!= -o jsonpath={.items[0].status.addresses[0].address})
NODE_IP=136.24.65.147
(set -x; curl -k https://$NODE_IP/?id='or+1=1--a-<script>prompt(1)</script>' -H "host: sidecar.example.com")

