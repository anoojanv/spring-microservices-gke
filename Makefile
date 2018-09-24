#	Copyright 2018, Google, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

PROJECT_ID=$(shell gcloud config list project --format=flattened | awk 'FNR == 1 {print $$2}')
ZONE=us-central1-a
CLUSTER_NAME=microservice-demo
GCLOUD_USER=$(shell gcloud config get-value core/account)
CONTAINER_NAME=microservice

ZIPKIN_POD_NAME=$(shell kubectl -n istio-system get pod -l app=zipkin -o jsonpath='{.items[0].metadata.name}')
JAEGER_POD_NAME=$(shell kubectl -n istio-system get pod -l app=jaeger -o jsonpath='{.items[0].metadata.name}')
SERVICEGRAPH_POD_NAME=$(shell kubectl -n istio-system get pod -l app=servicegraph -o jsonpath='{.items[0].metadata.name}')
GRAFANA_POD_NAME=$(shell kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}')
PROMETHEUS_POD_NAME=$(shell kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}')

create-cluster:
	gcloud container --project "$(PROJECT_ID)" clusters create "$(CLUSTER_NAME)" --zone "$(ZONE)" --machine-type "n1-standard-2" --image-type "COS" --disk-size "100" --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "4" --network "default" --enable-cloud-logging --enable-cloud-monitoring --cluster-version=1.10
	kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(GCLOUD_USER)

download-istio:
	wget https://github.com/istio/istio/releases/download/1.0.0/istio-1.0.0-linux.tar.gz
	tar -zxvf istio-1.0.0-linux.tar.gz

genereate-istio-template:
	helm template istio-1.0.0/install/kubernetes/helm/istio --name istio --namespace istio-system --set global.mtls.enabled=true --set tracing.enabled=true --set servicegraph.enabled=true --set grafana.enabled=true > istio.yaml

deploy-istio:
	kubectl create namespace istio-system
	kubectl apply -f istio.yaml
	kubectl label namespace default istio-injection=enabled --overwrite
	sleep 60

autoscale:
	kubectl autoscale deployment frontend --max 6 --min 4 --cpu-percent 50

switch-context:
	kubectl config use-context gke_${PROJECT_ID}_${ZONE}_${CLUSTER_NAME}

start-monitoring-services:
	$(shell kubectl -n istio-system port-forward $(JAEGER_POD_NAME) 16686:16686 & kubectl -n istio-system port-forward $(SERVICEGRAPH_POD_NAME) 8088:8088 & kubectl -n istio-system port-forward $(GRAFANA_POD_NAME) 3000:3000 & kubectl -n istio-system port-forward $(PROMETHEUS_POD_NAME) 9090:9090)

get-stuff:
	kubectl get pods && kubectl get svc && kubectl get svc istio-ingressgateway -n istio-system

delete-all:
	kubectl -n default delete services --all
	kubectl -n default delete deployments --all
	kubectl -n default delete pods --all
	kubectl -n default delete ingress --all

restart-demo:
	-kubectl delete svc --all
	-kubectl delete deployment --all
	-kubectl delete VirtualService --all
	-kubectl delete DestinationRule --all
	-kubectl delete Gateway --all
	-kubectl delete ServiceEntry --all
