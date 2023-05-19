#!/bin/bash
helm repo add vgpu-charts https://4paradigm.github.io/k8s-vgpu-scheduler
helm repo add stable https://charts.helm.sh/stable
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add gpu-helm-charts https://nvidia.github.io/dcgm-exporter/helm-charts
helm repo add utkuozdemir https://utkuozdemir.org/helm-charts
helm repo update

