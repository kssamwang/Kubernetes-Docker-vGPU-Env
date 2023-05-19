#!/bin/bash
kubectl delete -f metrics-server.yaml
kubectl delete -f recommended.yaml
kubectl delete serviceaccount dashboard-admin -n kube-system
kubectl delete clusterrolebinding dashboard-admin
