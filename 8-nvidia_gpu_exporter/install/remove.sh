#!/bin/bash
kubectl delete daemonset nvidia-gpu-exporter -n monitoring
kubectl delete service nvidia-gpu-exporter -n monitoring

