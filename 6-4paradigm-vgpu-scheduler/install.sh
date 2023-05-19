#!/bin/bash
kubectl taint nodes master node-role.kubernetes.io/master-
kubectl label nodes master gpu=on
kubectl label nodes worker01 gpu=on
kubectl label nodes worker02 gpu=on
helm repo add vgpu-charts https://4paradigm.github.io/k8s-vgpu-scheduler
kubectl version
helm install vgpu vgpu-charts/vgpu --set scheduler.kubeScheduler.imageTag=v1.23.6 -n kube-system
