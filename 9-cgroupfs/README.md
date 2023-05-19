# Kubernetes-Docker-vGPU-Env

## 9 使用CGroupfs作为Docker和Kubelet的CGroup Driver

Docker默认CGroup Driver是CGroup

k8s默认CGroup Driver是systemd

要保持二者一致才能使用

内核默认的cgroupfs版本为v1，可以启用v2

本分支提供将其配置为cgroupfs v2的方法

### 9.1 系统安装Cgroupfs v2

集群启动前就安装，安装后重启系统。

```sh
cd ./cgroupfs-v2-install
./install.sh
```

## 9.2 同步修改Docker/kubelet的Cgroup Driver

```sh
cd ./config/docker
./config.sh [master/worker] [systemd/cgroupfs]
cd ../config/kubelet
./config.sh [systemd/cgroupfs]
cd ../../
./restart.sh
```
