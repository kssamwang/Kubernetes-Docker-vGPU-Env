# Kubernetes-Docker-vGPU-Env
## 项目说明

搭建k8s+Docker运行GPU程序的环境，可指定分配GPU资源，实现cuda层隔离。

效果：k8s集群上初始化一个pod，其中的Docker容器获得指定数值的GPU资源，能够直接运行CUDA程序/机器学习。

默认已经安装了NVIDIA驱动，cuda toolkit，cudnn。

## 实验环境

腾讯云服务器   ：Ubuntu 20.04 V100

Driver Version: 470.82.01

CUDA Version  : 11.4.3

CUDNN Version : 8.2.4

Docker        : 20.10.12

Kubernetes    : 1.23.6

## 步骤

0. **所有node上进行** [安装NVIDIA驱动和CUDA](https://github.com/kssamwang/k8s-docker-GPU-env/tree/main/0-cuda)
1. **所有node上进行** [Docker + nvidia-docker2 安装](https://github.com/kssamwang/k8s-docker-GPU-env/tree/main/1-docker-install)

2. **所有node上进行** [k8s 环境安装 集群网络初始化](https://github.com/kssamwang/k8s-docker-GPU-env/tree/main/2-k8s-install)

    worker和master的网络配置略有不同。

3. **master上进行** [helm 安装](https://github.com/kssamwang/k8s-docker-GPU-env/tree/main/3-helm-install)

4. **可选** [go 安装](https://github.com/kssamwang/k8s-docker-GPU-env/tree/main/4-go-install)

5. **每一node分别进行不同操作** [k8s集群创建](https://github.com/kssamwang/k8s-docker-GPU-env/tree/main/5-cluster-establish)
    
    master初始化集群，每个worker加入集群。
    
    也可以在此时就配置使用cgroupfs而不是systemd作为CGroup Driver。

6. **master上进行** [vgpu插件 安装](https://github.com/kssamwang/k8s-docker-GPU-env/tree/main/6-4paradigm-vgpu-scheduler)

7. **master上进行** [prometheus 安装](https://github.com/kssamwang/k8s-docker-GPU-env/tree/main/7-prometheus)

    注意，在worker上也要先执行pull.sh脚本，拉取代替镜像。
    
    Prometheus、Grafana、AlertManager建议开启外网访问。

8. **所有node上进行** [nvidia_gpu_exporter 安装](https://github.com/kssamwang/k8s-docker-GPU-env/tree/main/8-nvidia_gpu_exporter)

    如果选用helm安装nvidia_gpu_exporter，只需要master操作。

9. **所有node上进行** [Docker + kubelet 启用cgroupfs](https://github.com/kssamwang/k8s-docker-GPU-env/tree/main/9-cgroupfs)
    
    注意worker和master设置方式略有不同，cgroupfs v2启用内核后不用再做。
   
10. **master上进行** [Koordinator 安装部署](https://github.com/kssamwang/k8s-docker-GPU-env/tree/main/A-koordinator)

    其中Koordinator部署时，koord-runtime-proxy需要先统一启用cgroupfs。

11. **所有node上进行** [DCGM 安装部署](https://github.com/kssamwang/Kubernetes-Docker-vGPU-Env/tree/main/B-DCGM)

    集群搭建前配置DCGM系统服务并启动

12. **master上进行** [Kubernetes DashBoard 安装部署](https://github.com/kssamwang/k8s-docker-GPU-env/tree/main/C-DashBoard)
    
    集群搭建好以后启动Kubernetes Dashboard，使用token进行外网访问

## 环境搭建顺序

### Kubernetes集群启动前

上述步骤：

0 -> 1 -> 2 -> 3 -> 4 -> 8(deb安装版)/B -> 9(启用内核CGroupfs V2)

### Kubernetes集群启动后

上述步骤：

9(若使用CGroupfs代替systemd，修改配置文件) -> 5 -> { 6, 7, 8(helm安装版), C } -> 10(确保9中配置文件设置了docker socket参数)

可选：

+ Prometheus启动后接入GPU监控数据：DCGM或nvidia-gpu-exporter

    两个会竞争8080端口，功能接近，用一个就可以

+ Kubernetes Dashboard

    集群搭建好以后就可以配置

制作集群启动前的腾讯云系统镜像，开机后执行5中检查脚本即可。
