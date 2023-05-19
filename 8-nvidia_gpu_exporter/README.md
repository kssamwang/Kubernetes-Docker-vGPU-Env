# Kubernetes-Docker-vGPU-Env

## 8. GPU插件nvidia_gpu_exporter配置

建议方式：1,2 安装系统服务，再使用4接入prometheus

### 8.1 下载安装
多种安装方式：
https://github.com/utkuozdemir/nvidia_gpu_exporter/blob/master/INSTALL.md
推荐使用静态deb包安装。

安装完成后，可以查看命令。
```sh
nvidia_gpu_exporter --help
```

### 8.2 配置系统服务
编辑配置文件。
```sh
vim /lib/systemd/system/nvidia_gpu_exporter.service
```

```conf
[Unit]
Description=Nvidia GPU Exporter
After=network-online.target

[Service]
Type=simple

User=root
Group=root

ExecStart=/usr/bin/nvidia_gpu_exporter

SyslogIdentifier=nvidia_gpu_exporter

Restart=always
RestartSec=1

NoNewPrivileges=yes

ProtectHome=yes
ProtectSystem=strict
ProtectControlGroups=true
ProtectKernelModules=true
ProtectKernelTunables=yes
ProtectHostname=yes
ProtectKernelLogs=yes
ProtectProc=yes

[Install]
WantedBy=multi-user.target
```

重启服务。
```sh
systemctl daemon-reload
systemctl start nvidia_gpu_exporter.service
systemctl enable nvidia_gpu_exporter.service
systemctl status nvidia_gpu_exporter.service
```

重启后，默认监听9835端口，通过内网IP和监听端口，即可请求到收集的信息。
```sh
curl http://10.206.0.10:9835/metrics
```

### 8.3 在k8s集群中用helm安装
官方chart:
https://artifacthub.io/packages/helm/utkuozdemir/nvidia-gpu-exporter

安装:
```sh
helm repo add utkuozdemir https://utkuozdemir.org/helm-charts
helm repo update
helm install nvidia-gpu-exporter utkuozdemir/nvidia-gpu-exporter -n monitoring
```

删除:
```sh
kubectl delete daemonset nvidia-gpu-exporter -n monitoring
kubectl delete service nvidia-gpu-exporter -n monitoring
```

安装后获取数据:
```
root@master:~# helm install monitoring utkuozdemir/nvidia-gpu-exporter -n monitoring
NAME: monitoring
LAST DEPLOYED: Sun Apr 23 22:00:34 2023
NAMESPACE: monitoring
STATUS: deployed
REVISION: 1
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace monitoring -l "app.kubernetes.io/name=nvidia-gpu-exporter,app.kubernetes.io/instance=monitoring" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace monitoring $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace monitoring port-forward $POD_NAME 8080:$CONTAINER_PORT
root@master:~# kubectl get pods -A
NAMESPACE            NAME                                   READY   STATUS    RESTARTS        AGE
monitoring           monitoring-nvidia-gpu-exporter-4gx9q   1/1     Running   0               23s
monitoring           monitoring-nvidia-gpu-exporter-8g6jb   1/1     Running   0               23s
monitoring           monitoring-nvidia-gpu-exporter-g89mg   1/1     Running   0               23s
```

### 8.4 将数据接入prometheus
首先确认服务处于active:
```sh
systemctl status nvidia_gpu_exporter.service
```

然后依次创建endpoints、service、serviceMonitor到kube-prometheus的命名空间中。

创建Endpoints：gpu-exporter-endpoint.yaml
```yaml
apiVersion: v1
kind: Endpoints
metadata:
  name: nvidia-gpu-exporter
  namespace: monitoring
subsets:
  - addresses: 
    - ip: 172.17.0.3
    - ip: 172.17.0.8 # 直接这样添加集群中各个主机的内网IP
    ports:
    - name: http
      port: 9835
      protocol: TCP
```

```sh
kubectl apply -f gpu-exporter-endpoint.yaml
```

创建service: gpu-exporter-service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: nvidia-gpu-exporter
  name: nvidia-gpu-exporter
  namespace: monitoring
spec:
  ports:
  - name: http
    protocol: TCP
    port: 9835
    targetPort: http
  type: ClusterIP
```

```sh
kubectl apply -f gpu-exporter-service.yaml
```

创建serviceMonitor: gpu-exporter-serviceMonitor.yaml
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app: nvidia-gpu-exporter
  name: nvidia-gpu-exporter
  namespace: monitoring
spec:
  endpoints:
  - interval: 30s
    port: http
  jobLabel: app
  selector:
    matchLabels:
      app: nvidia-gpu-exporter
```

```sh
kubectl apply -f gpu-exporter-serviceMonitor.yaml
```

注意放通9835端口。加载一段时间后，prometheus即可收到数据。可以使用的Grafana模板ID：14574。

卸载：
```sh
kubectl delete -f gpu-exporter-service.yaml
kubectl delete -f gpu-exporter-serviceMonitor.yaml
```
