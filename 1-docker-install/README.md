# k8s-docker-GPU-env
搭建k8s+docker运行GPU程序的环境

## 1 docker GPU环境搭建
默认已安装NVIDIA驱动，CUDA Toolkit

安装docker和nvidia-docker2

```sh
./docker-install.sh master
./docker-install.sh worker
```

安装时
default=N
