# k8s-docker-GPU-env
搭建k8s+docker运行GPU程序的环境

## 6. 安装配置第四范式vGPU插件

[项目地址](https://github.com/4paradigm/k8s-vgpu-scheduler/blob/master/README_cn.md)

### 1 检查docker配置文件
```sh
cat /etc/docker/daemon.json
```

默认runtime必须是nvidia，此步骤安装docker和nvidia-docker2后应该就配好了

```json
{
  "default-runtime": "nvidia",
  "runtimes": {
    "nvidia": {
      "path": "/usr/bin/nvidia-container-runtime",
      "runtimeArgs": []
    }
  }
}
```

### 2 设置集群中有GPU的服务器可以被调度到

master上给结点打上gpu可用的标签

```sh
kubectl label nodes {nodeid} gpu=on
```

如果要让master同时参与pod分配调度，需要额外的一些设置，见10.5。

### 3 安装插件
安装时k8s版本号对应

```sh
helm repo add vgpu-charts https://4paradigm.github.io/k8s-vgpu-scheduler
kubectl version
helm install vgpu vgpu-charts/vgpu --set scheduler.kubeScheduler.imageTag=v1.23.6 -n kube-system
```

安装完成后，看到vgpu-device-plugin与vgpu-scheduler两个pod状态为Running即为安装成功。

```sh
kubectl get pods -n kube-system
```

### 使用插件部署一个使用限定GPU资源的pod

NVIDIA vGPUs 现在能透过资源类型 nvidia.com/gpu 被容器请求：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-pod
spec:
  containers:
  - name: ubuntu-container
    image: ubuntu:20.04
    command: ["bash", "-c", "sleep 86400"]
    resources:
      limits:
        nvidia.com/gpu: 1 # 请求1个vGPUs
        nvidia.com/gpumem: 3000 # 每个vGPU申请3000m显存 （可选，整数类型）
        nvidia.com/gpucores: 30 # 每个vGPU的算力为30%实际显卡的算力 （可选，整数类型）
```

将上面的文件保存为gpu-pod.yaml。
使用kubectl apply命令部署带GPU的容器
```sh
kubectl apply -f gpu-pod.yaml
```

在pod所属的node上查看容器。

```sh
docker ps -a
```

进入Docker指定的id：
```sh
docker exec -it  {容器id}  /bin/bash
```

可以在容器执行 nvidia-smi 命令，然后比较vGPU和实际GPU显存大小的不同。
此时容器中执行该命令，看到的GPU数和显存是分配的数值，如果开始运行程序，不会超过算力使用率上限。
如果你的任务无法运行在任何一个节点上，那么任务pod会卡在pending状态。

监控vGPU使用情况
调度器部署成功后，监控默认自动开启，你可以通过 http://{nodeip}:{monitorPort}/metrics
来获取监控数据，其中monitorPort可以在Values中进行配置，默认为31992
注意 节点上的vGPU状态只有在其使用vGPU后才会被统计

### 5 设置master可以参与pod调度
Unschedulable表示节点是否参与pod调度，master默认情况下为false。

```sh
kubectl describe node master
```
```
Taints:             node-role.kubernetes.io/master:NoSchedule
Unschedulable:      false
```

首先，去掉master不参与pod调度的污点（taint）
```sh
kubectl taint nodes master node-role.kubernetes.io/master-
```

然后，在pod的启动yaml的spec字段中，加入允许污点的字段，如此该pod可以被调度到master上。

```yaml
 spec:
   tolerations:
    - key: node-role.kubernetes.io/master
      operator: Exists
      effect: NoSchedule
```

注意master上打上gpu=on，设置master参与pod调度后半分钟左右，原来处于pending的GPU任务pod可以被自动调度到master上。

关闭master参与pod调度的命令：
```sh
kubectl taint nodes master node-role.kubernetes.io/master=:NoSchedule
```

将master上已经存在的Pod驱逐出去的命令：
```sh
kubectl taint nodes master node-role.kubernetes.io/master=:NoExecute
```
