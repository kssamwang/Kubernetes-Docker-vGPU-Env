# Kubernetes-Docker-vGPU-Env

## 7. k8s安装配置Prometheus

### 7.1 下载kube-prometheus包安装

选择版本v0.10.0
```sh
git clone -b v0.10.0 https://github.com/prometheus-operator/kube-prometheus.git
cd kube-prometheus
```

安装
```sh
# Create the namespace and CRDs, and then wait for them to be availble before creating the remaining resources
kubectl create -f manifests/setup

# Wait until the "servicemonitors" CRD is created. The message "No resources found" means success in this context.
until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done

kubectl create -f manifests/
```

移除
```sh
kubectl delete --ignore-not-found=true -f manifests/ -f manifests/setup
```

### 7.2 查看监控组件信息
查看CRD类型
```sh
kubectl get crd | grep coreos
```

查看特定CRD类型下实例
```sh
kubectl get prometheuses -n monitoring
kubectl get servicemonitors -n monitoring
```

查看创建的service
```sh
kubectl get svc -n monitoring
```

查询monitoring命名空间所有组件的状态
```sh
kubectl get po -n monitoring
```

查询非Running状态pod的方法，可以获得容器启动失败的原因
```sh
kubectl describe  po prometheus-adapter-7858d4ddfd-55lnq  -n monitoring
```

### 7.3 解决组件所需镜像 ImagePullBackOff / ErrImageNeverPull
参考：https://blog.csdn.net/qq_45439217/article/details/123477846
#### 7.3.1 prometheus-adapter
拉取可以替代的镜像到本地，打上标签
```sh
docker pull lbbi/prometheus-adapter:v0.9.1
docker tag docker.io/lbbi/prometheus-adapter:v0.9.1 k8s.gcr.io/prometheus-adapter:v0.9.1
```
注意，此拉取步骤在master和worker上都要进行。

```sh
vi manifests/prometheusAdapter-deployment.yaml
```

文件内容：
```
***              修改前               ***
 
        image: k8s.gcr.io/prometheus-adapter/prometheus-adapter:v0.9.1
        name: prometheus-adapter
 
***              修改后               ***
 
        # image: k8s.gcr.io/prometheus-adapter/prometheus-adapter:v0.9.1
        image: k8s.gcr.io/prometheus-adapter:v0.9.1   #  容器镜像标签，写错拉取本地镜像失败。
        imagePullPolicy: Never                        #  imagePullPolicy: Always 总是网络拉取镜像, 是k8s默认的拉取方式。
                                                      #  imagePullPolicy: Never 从不远程拉取镜像，只读取本地镜像。
                                                      #  imagePullPolicy: IfNotPresent 优先拉取本地镜像。
        name: prometheus-adapter 
```

重新执行该组件pod的yaml文件。
```sh
kubectl replace -f manifests/prometheusAdapter-deployment.yaml
```

#### 7.3.2 kube-state-metrics
拉取可以替代的镜像到本地，打上标签
```sh
docker pull bitnami/kube-state-metrics:2.3.0
```

```sh
vi manifests/kubeStateMetrics-deployment.yaml
```

文件内容：
```
***              修改前               ***
 
        image: k8s.gcr.io/kube-state-metrics/kube-state-metrics:2.3.0
        name: kube-state-metrics
 
***              修改后               ***
 
        # image: k8s.gcr.io/kube-state-metrics/kube-state-metrics:2.3.0
        image: docker.io/bitnami/kube-state-metrics:2.3.0
        imagePullPolicy: IfNotPresent
        name: kube-state-metrics
```

重新执行该组件pod的yaml文件。
```sh
kubectl replace -f manifests/kubeStateMetrics-deployment.yaml
```

### 7.4 配置外网访问
方法是使用kubectl edit修改三者的service配置。为端口增加nodePort字段作为外网转发端口，将type字段的值从ClusterIp改为NodePort

#### 7.4.1 prometheus

```sh
kubectl edit svc prometheus-k8s -n monitoring
```

```yaml
  ports:
  - name: web
    nodePort: 32539 # 新增
    port: 9090
    protocol: TCP
    targetPort: web
  - name: reloader-web # 新增
    nodePort: 32353
    port: 8080
    protocol: TCP
    targetPort: reloader-web
  type: NodePort  # ClusterIP
```

#### 7.4.2 grafana

```sh
kubectl edit svc grafana -n monitoring
```

```yaml
  ports:
  - name: http
    nodePort: 31757 # 新增
    port: 3000
    protocol: TCP
    targetPort: http
  type: NodePort  # ClusterIP
```

#### 7.4.3 alertmanager

```sh
kubectl edit svc alertmanager-main -n monitoring 
```

```yaml
  ports:
  - name: web
    nodePort: 31206
    port: 9093
    protocol: TCP
    targetPort: web
  - name: reloader-web
    nodePort: 30476
    port: 8080
    protocol: TCP
    targetPort: reloader-web
  type: NodePort
```

#### 7.4.4 使用方法
完成上述配置后执行
```sh
kubectl get svc -n monitoring | grep -i nodeport
```

可以看到

```
alertmanager-main       NodePort    10.106.73.220   <none>        9093:31206/TCP,8080:30476/TCP   14m
grafana                 NodePort    10.109.94.127   <none>        3000:31757/TCP                  14m
prometheus-k8s          NodePort    10.96.108.56    <none>        9090:32539/TCP,8080:32353/TCP   14m
```

即完成了上述端口转发，需要设置腾讯云安全组放通上述端口。

访问prometheus：

```
http://<master 公网IP>:32539
```

其中/targets可以查看监控数据加载情况。

访问grafana：
```
http://<master 公网IP>:31757
```

grafana有用户名和密码。初始用户名密码均为admin，首次登录后会强制修改admin密码。

通过create->import选择加载的模板。

可以使用的DCGM Grafana模板ID：
12219
15117
18288
13580

通用的监控面板ID
K8S for Prometheus Dashboard 20211010中文版
13105

访问alertmanager：
```
http://<master 公网IP>:31206
```
