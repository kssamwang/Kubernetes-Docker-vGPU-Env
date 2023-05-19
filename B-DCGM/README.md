## 11. NVIDIA DCGM安装使用
NVIDIA DCGM是采集GPU监控数据的软件。
### 11.1 安装并配置服务
```sh
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb
sudo dpkg -i cuda-keyring_1.0-1_all.deb
sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /"
sudo apt-get update && sudo apt-get install -y datacenter-gpu-manager
sudo systemctl --now enable nvidia-dcgm
sudo systemctl status nvidia-dcgm
```

### 11.2 在helm上安装并将数据接入prometheus
需要将dcgm安装到kube-prometheus同一个namespace中：

```sh
helm repo add gpu-helm-charts https://nvidia.github.io/dcgm-exporter/helm-charts
helm repo update
helm install --generate-name gpu-helm-charts/dcgm-exporter -n monitoring
```

出现一下内容即为安装成功。按照提示进行端口转发。
```
NAME: dcgm-exporter-1684275290
LAST DEPLOYED: Wed May 17 06:14:51 2023
NAMESPACE: monitoring
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods -n monitoring -l "app.kubernetes.io/name=dcgm-exporter,app.kubernetes.io/instance=dcgm-exporter-1684275290" -o jsonpath="{.items[0].metadata.name}")
  kubectl -n monitoring port-forward $POD_NAME 8080:9400 &
  echo "Visit http://127.0.0.1:8080/metrics to use your application"
```

```sh
export POD_NAME=$(kubectl get pods -n monitoring -l "app.kubernetes.io/name=dcgm-exporter,app.kubernetes.io/instance=dcgm-exporter-1684275290" -o jsonpath="{.items[0].metadata.name}")
nohup kubectl -n monitoring port-forward $POD_NAME 8080:9400  1>/dev/null 2>&1 &
```

完成后访问prometheus的targets，可以看到数据。

可以使用的DCGM Grafana模板ID：

12219

15117

18288

13580

注意dcgm与nvidia-gpu-exporter竞争8080，二者只能启动一个
dcgm上传数据到prometheus速度慢。


### 11.3 卸载
```sh
helm uninstall dcgm-exporter-xxxxxxxxxx  -n monitoring
```
