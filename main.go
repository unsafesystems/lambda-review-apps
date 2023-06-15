package main

import (
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/awslabs/aws-lambda-go-api-proxy/httpadapter"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
)

func main() {
	proxyTarget, err := url.Parse("http://localhost:8081")
	if err != nil {
		panic(err)
	}

	// Proxy to the downstream server.
	proxy := &httputil.ReverseProxy{
		Rewrite: func(r *httputil.ProxyRequest) {
			r.SetXForwarded()
			r.SetURL(proxyTarget)
		},
	}

	isLambda := os.Getenv("LAMBDA_TASK_ROOT") != ""

	if isLambda {
		lambda.Start(httpadapter.New(proxy).ProxyWithContext)
	} else {
		log.Fatal(http.ListenAndServe(":8080", proxy))
	}
}
