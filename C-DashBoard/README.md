# Kubernetes-Docker-vGPU-Env

## C. 安装配置k8s Dashboard

创建DashBoard。
```sh
kubectl apply -f metrics-server.yaml
kubectl apply -f recommended.yaml
```

等待dashboard的pod处于Running。

```sh
kubectl get pods -A | grep dashboard
```

```sh
# 创建用户
kubectl create serviceaccount dashboard-admin -n kube-system
# 用户授权
kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
# 获取用户Token
kubectl describe secrets -n kube-system $(kubectl -n kube-system get secret | awk '/dashboard-admin/{print $1}')
```

用Firefox浏览器访问，Chrome和Edge不行。

```
https://<master ip>:30001
```

选择“高级”->“接受风险并继续”

选择Token方式登录，输入前面拿到的Token即可。
