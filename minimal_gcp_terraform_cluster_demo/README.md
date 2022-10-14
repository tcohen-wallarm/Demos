
- [Minimal Terraform GCP Cluster Demo](#minimal-terraform-gcp-cluster-demo)
  - [Terraform configuration file](#terraform-configuration-file)
  - [Build](#build)
  - [Run](#run)
  - [Test](#test)
  - [Delete](#delete)

# Minimal Terraform GCP Cluster Demo

> The following demo deploys a 2x node Wallarm cluster using an SSL proxy configuration along with 2x demo upstreams using terraform.

> Requirements:
> - GCP Account
> - Terraform 

## Terraform configuration file


Create a terraform configurartion file:

`vi variables.auto.tfvars`

with the following config:


```
# Required variables
gcp_project = "your_gcp_project"
gcp_region = "us-west2"
az_count = "2"
name_prefix = "test"
wallarm_deploy_username = "your@email.com"
wallarm_deploy_password = "your_pwd"
wallarm_api_domain = "us1.api.wallarm.com"
```

## Build

```
sh build.sh
```

## Run 

```
sh run.sh
```

## Test 

```
sh test.sh "your_gcp_lb_ip"
```

## Delete 

```
sh del.sh
```

> For more information on Terraform deployments in GCP:
> 
> https://docs.wallarm.com/admin-en/installation-gcp-en/#launch-the-instance-via-terraform-or-other-tools