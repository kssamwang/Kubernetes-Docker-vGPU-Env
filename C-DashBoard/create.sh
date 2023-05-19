#!/bin/bash
kubectl apply -f metrics-server.yaml
kubectl apply -f recommended.yaml
allpods=$(kubectl get pods -n  kubernetes-dashboard | wc -l)
running=$(kubectl get pods -n  kubernetes-dashboard | grep Running | wc -l)
while [ $allpods != $running + 1 ]
do
	sleep 1
done

# 创建用户
kubectl create serviceaccount dashboard-admin -n kube-system
# 用户授权
kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
# 获取用户Token
kubectl describe secrets -n kube-system $(kubectl -n kube-system get secret | awk '/dashboard-admin/{print $1}')

echo "please visit https://<master ip>:30001 by Firefox instead of Chrome/Edge."

