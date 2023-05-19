# Kubernetes-Docker-vGPU-Env
搭建k8s+docker运行GPU程序的环境

## 2 安装k8s并初始化集群设置
此步骤master和worker一样

```sh
./k8s-install.sh
```

## 初始化集群网络
此步骤master和worker一样

```sh
./cluster-init.sh
```

## 安装网络工具
此步骤master和worker一样

```sh
./networktools-install.sh
```

## 修改主机名
```sh
sudo hostnamectl set-hostname worker01
```

编辑/etc/hosts文件如下

127.0.0.1 [hostname]

127.0.1.1 localhost.localdomain [hostname]

集群中node内网IP node主机名

```
#
127.0.1.1 localhost.localdomain worker02
127.0.0.1 worker02
172.17.0.8 master
172.17.0.11 worker01
172.17.0.3 worker02

::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
```
