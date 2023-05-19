# k8s-docker-GPU-env
搭建k8s+docker运行GPU程序的环境

安装prometheus监视器

解决了一些docker镜像缺失问题

[详见](https://github.com/kssamwang/kube-prometheus)

在master/worker上拉取镜像
```sh
docker pull lbbi/prometheus-adapter:v0.9.1
docker tag docker.io/lbbi/prometheus-adapter:v0.9.1 k8s.gcr.io/prometheus-adapter:v0.9.1
docker pull bitnami/kube-state-metrics:2.3.0
```

在master上安装prometheus
```sh
git clone https://github.com/kssamwang/kube-prometheus.git
cd kube-prometheus
# Create the namespace and CRDs, and then wait for them to be availble before creating the remaining resources
kubectl create -f manifests/setup
# Wait until the "servicemonitors" CRD is created. The message "No resources found" means success in this context.
until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
kubectl create -f manifests/
```