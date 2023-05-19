# k8s-docker-GPU-env
搭建k8s+docker运行GPU程序的环境

## 8 安装nvidia-gpu-exporter
有以下两种安装方法

### 1 使用deb安装成系统服务
#### 下载安装
多种安装方式：

[nvidia-gpu-exporter](https://github.com/utkuozdemir/nvidia_gpu_exporter/blob/master/INSTALL.md)

推荐使用静态deb包为每一个node安装。

安装完成后，可以查看命令。
```sh
nvidia_gpu_exporter --help
```

#### 配置系统服务
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

重启后，默认监听9835端口，通过内网IP和监听端口，即可请求到收集的信息，注意放通端口。
```sh
curl http://localhost:9835/metrics
```

### 2 使用helm安装
[官方chart](https://artifacthub.io/packages/helm/utkuozdemir/nvidia-gpu-exporter)

安装:

```sh
helm repo add utkuozdemir https://utkuozdemir.org/helm-charts
helm install monitoring utkuozdemir/nvidia-gpu-exporter -n monitoring
```

安装成功:
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
```

删除pod:

```sh
kubectl delete pod monitoring-nvidia-gpu-exporter-xxxx
```
