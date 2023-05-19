#!/bin/bash
docker pull lbbi/prometheus-adapter:v0.9.1
docker tag docker.io/lbbi/prometheus-adapter:v0.9.1 k8s.gcr.io/prometheus-adapter:v0.9.1
docker pull bitnami/kube-state-metrics:2.3.0
docker pull registry.aliyuncs.com/google_containers/kube-apiserver:v1.23.17
docker pull registry.aliyuncs.com/google_containers/kube-scheduler:v1.23.17
docker pull registry.aliyuncs.com/google_containers/kube-proxy:v1.23.17
docker pull registry.aliyuncs.com/google_containers/kube-controller-manager:v1.23.17
docker pull registry.aliyuncs.com/google_containers/etcd:3.5.1-0
docker pull registry.aliyuncs.com/google_containers/coredns:v1.8.6
docker pull registry.aliyuncs.com/google_containers/pause:3.6
docker pull jimmidyson/configmap-reload:v0.5.0
docker pull quay.io/prometheus/blackbox-exporter:v0.19.0
docker pull quay.io/brancz/kube-rbac-proxy:v0.11.0
docker pull grafana/grafana:8.3.3
docker pull quay.io/prometheus-operator/prometheus-operator:v0.53.1
docker pull quay.io/prometheus/prometheus:v2.32.1
docker pull quay.io/prometheus-operator/prometheus-config-reloader:v0.53.1
docker pull quay.io/prometheus/alertmanager:v0.23.0
docker pull quay.io/prometheus/node-exporter:v1.3.1

