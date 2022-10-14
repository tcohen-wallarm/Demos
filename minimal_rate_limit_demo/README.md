- [Minimal Rate Limit Demo](#minimal-rate-limit-demo)
  - [Create an authentication file](#create-an-authentication-file)
  - [Source your file](#source-your-file)
  - [Run an upstream app](#run-an-upstream-app)
  - [Run a Wallarm node](#run-a-wallarm-node)
  - [Tests](#tests)
    - [Rate limit test](#rate-limit-test)
    - [Not rate limit test](#not-rate-limit-test)
  - [Delete demo](#delete-demo)


# Minimal Rate Limit Demo

> Demo runs in Docker and deploys a Wallarm node and a sample upstream app.
> In this demo Wallarm will rate-limit connections exceeding 5 requests /1 second in POST 
> and GET HTTP requests.

> Requirements: 
> - Linux
> - Docker
> - Vegeta

## Create an authentication file

`
vi auth
`


And add the following

```
export WC_DEPLOY_USER="your@email.com" 
export WC_DEPLOY_PASSWORD='your_wallarm_console_pwd'
```

## Source your file

```
. ./auth
```

## Run an upstream app

```
sh run-upstream.sh
```

## Run a Wallarm node

```
sh run-wallarm.sh
```

## Tests

### Rate limit test

```
echo "GET http://localhost:8080/index.html" | vegeta attack -duration=10s -rate=6 | vegeta report
```

### Not rate limit test

```
echo "GET http://localhost:8080/index.html" | vegeta attack -duration=10s -rate=4 | vegeta report
```

> Note that this test uses vegeta and it will need to be installed in the system. For more info:
> 
>  https://github.com/tsenart/vegeta

## Delete demo

```
sh stop.sh
```



