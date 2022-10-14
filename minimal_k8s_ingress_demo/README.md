- [Minimal Kubernetes Ingress Demo](#minimal-kubernetes-ingress-demo)
  - [Authentication file](#authentication-file)
  - [Build, Run and Delete](#build-run-and-delete)


# Minimal Kubernetes Ingress Demo

> In this demo we perform a Wallarm Node installation in a Kubernetes cluster.
> 
> The following tasks are shown:
> 
> - Deploy Wallarm ingress using Helm in Kubernetes 
> - Verify that all Wallarm components are running
> - Install a coffee and tea ingress sample app
> - Set Wallarm in monitoring mode 
> - Run ***sqli***
> and ***xss*** attacks on the node

> ***Requirements:***
> - K8s cluster with kubeconfig working 
> - helm installed
> - Wallarm demo account

## Authentication file
Create a terraform authentication file:

`vi auth`

with the following config:


```
export WALLARM_CLOUD_NODE_TOKEN=myWallARMnodeTOKen
```

source auth

```
. ./auth
```

## Build, Run and Delete

```
sh demo.sh
```

> For detailed documentation visit: https://docs.wallarm.com/admin-en/installation-kubernetes-en/


















