# Spring Boot Microservice with GKE/Istio

This is some boilerplate code to get started with deploying spring boot on GKE (Google Kubernetes Engine)

# Setup

## Cluster Setup
You will need a Kubernetes Cluster.

You will also need Docker and kubectl 1.9.x or newer installed on your machine, as well as the Google Cloud SDK. You can install the Google Cloud SDK (which will also install kubectl) [here](https://cloud.google.com/sdk).

To create the cluster with Google Kubernetes Engine, run this command:

`make create-cluster`


## Istio Setup
This project assumes you are running on x64 Linux. If you are running on another platform, I highly reccomend using [Google Cloud Shell](https://cloud.google.com/shell) to get a free x64 Linux environment.

To deploy Istio into the cluster, run

`make deploy-istio`

This will deploy the Istio services and control plane into your Kubernetes Cluster. Istio will create its own Kubernetes Namespace and a bunch of services and deployments. In addition, this command will install helper services. Jaeger for tracing, Prometheus for monitoring, Servicegraph to visualize your microservices, and Grafana for viewing metrics.

## Launch Grafana, Prometheus, Jaegar and ServiceGraph 

Run this in another terminal:

`make start-monitoring`

This will create tunnels into your Kubernetes cluster for [Jaeger](http://localhost:16686), [Servicegraph](http://localhost:8088), and [Grafana](http://localhost:3000). This command will not exit as it keeps the connection open.


## Deploy Kubernetes Services

This will create the Deployments and Services.

`kubectl apply -f kube/`

## Apply Istio Configs

Apply the istio configs to create the Gateway and Virtual Services

`kubectl apply -f istio/`

# Monitoring and Tracing

A awesome benefit of Istio is that it automatically adds tracing and monitoring support to your apps. While monitoring is added for free, tracing needs you to forward the trace headers that Istio's Ingress controller automatically injects so Istio can stitch together the requests. You need to forward the following headers in your code:

```
    'x-request-id'
    'x-b3-traceid'
    'x-b3-spanid'
    'x-b3-parentspanid'
    'x-b3-sampled'
    'x-b3-flags'
    'x-ot-span-context'
```

The sample microservice you deployed already does this on the '/v1' endpoint

## Viewing Traces

Now, you can open [Jaeger](http://localhost:16686/), select the "frontend" service, and click "Find Traces". Istio will sample your requests, so not every request will be logged.

Click a Trace, and you can see a waterfall of the requests. Because we set the "fail" header, we can also see Istio's auto-retry mechanism in action!

![Jaeger Trace](./jaeger.gif)

## Viewing Metrics

To view Metrics, open [Grafana](http://localhost:3000/dashboard/db/istio-dashboard)

You can see a lot of cool metrics in the default Istio dashboard, or customize it as you see fit!

![Grafana Dashboard](./grafana.png)
