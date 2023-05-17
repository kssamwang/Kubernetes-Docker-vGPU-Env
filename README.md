# Kubernetes-Docker-vGPU-Env
## 0. 服务器环境
实验室服务器：Ubuntu20.04，cuda 12.1，一台4张NVIDIA V100-16G，另一台4张NVIDIA A100-32G

测试租用腾讯云服务器GPU计算型：Ubuntu20.04，1张NVIDIA V100-32G，cuda 11.4

腾讯云上，同一用户租用同一分区多台主机时，内网IP同网段（关机后重启，分配的公网IP会变，但内网IP不变）。

注意：docker和k8s的版本对应关系异常严格，k8s从1.24起不再支持docker

## 1. 安装cuda环境

确定可用cuda版本，官网下载，https://developer.nvidia.com/cuda-toolkit-archive 推荐使用runfile(local)安装

存在驱动时，不能重复安装。以下以Ubuntu 20.04 x86——64 安装cuda 11.4版本为例：

```sh
nvidia-smi
wget https://developer.download.nvidia.com/compute/cuda/11.4.0/local_installers/cuda_11.4.0_470.42.01_linux.run
sudo sh cuda_11.4.0_470.42.01_linux.run
```
运行后勾选组件即可。

**配置环境变量，注意腾讯云GPU服务器启动时选自动安装GPU驱动，开机后过一段时间，后台自动安装完，直接到这一步配置环境变量就可以。**

path中注意替换版本号。配置后验证，出现nvcc编译器版本即为成功安装cuda工具链。

```sh
sudo echo -e "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-11.4/lib64" >> /etc/profile
sudo echo -e "export PATH=$PATH:/usr/local/cuda-11.4/bin" >> /etc/profile
source /etc/profile
nvcc -V
```

## 2. 安装docker并配置容器镜像

### 2.1 docker基本安装配置

#### Step 1: 安装必要的一些系统工具
```sh
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
```

#### Step 2: 安装GPG证书
```sh
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
```

#### Step 3: 写入软件源信息,设置稳定版仓库
```sh
sudo add-apt-repository "deb https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
```

#### Step 4: 查看可以安装的docker稳定版本，选择20.10.12
```sh
sudo apt-cache madison docker-ce
sudo apt-cache madison docker-ce-cli
sudo apt-cache madison containerd.io
sudo apt-get install -y docker-ce=5:20.10.12~3-0~ubuntu-focal docker-ce-cli=5:20.10.12~3-0~ubuntu-focal containerd.io
```

```sh
sudo apt-cache madison docker-ce
sudo apt-cache madison docker-ce-cli
sudo apt-cache madison containerd.io
sudo apt-get install -y docker-ce=5:20.10.12~3-0~ubuntu-bionic docker-ce-cli=5:20.10.12~3-0~ubuntu-bionic containerd.io
```

#### Step 5：确认版本，启动docker
```sh
docker version
sudo systemctl start docker && sudo systemctl enable docker
```

### 2.2 安装nvidia-docker2
注意：nvidia-docker2和nvidia-container-runtime是包含关系，一般安装nvidia-docker2更好。

下载获取GPG证书，设置仓库源后安装。
```sh
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) 
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - 
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get clean 
sudo apt-get update
sudo apt-get install -y nvidia-docker2
```

### 2.3 编辑docker配置文件
设置一些镜像
```sh
sudo vi /etc/docker/daemon.json
```

此docker配置文件适用node，master还需要其他字段。

```json
{
 "registry-mirrors" : [
   "https://mirror.ccs.tencentyun.com",
   "http://registry.docker-cn.com",
   "http://docker.mirrors.ustc.edu.cn",
   "http://hub-mirror.c.163.com",
   "https://xjuddlv8.mirror.aliyuncs.com"
 ],
 "insecure-registries" : [
   "registry.docker-cn.com",
   "docker.mirrors.ustc.edu.cn"
 ],
 "exec-opts": [ "native.cgroupdriver=systemd" ],
 "debug" : true,
 "experimental" : true,
 "default-runtime": "nvidia",
 "runtimes": {
    "nvidia": {
      "path": "/usr/bin/nvidia-container-runtime",
      "runtimeArgs": []
    }
  }
}
```

修改docker配置文件后重新启动docker。

```sh
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### 2.4 拉取/启动一个cuda的docker容器

拉取一个cuda-devel，devel含有cuda完整编译工具链，版本11.4.0，注意要写完整小版本号。

版本号参考：https://gitlab.com/nvidia/container-images/cuda/blob/master/doc/supported-tags.md

```sh
docker pull nvidia/cuda:11.4.0-devel-ubuntu20.04
docker run --runtime=nvidia --rm nvidia/cuda:11.4.0-devel-ubuntu20.04 nvidia-smi
docker run -it --ipc=host --gpus all -v /home/wsy --restart=always --name develop -p kssamwang/gx-plug:v3.0-PowerGraph
```

第一次下载镜像到本地时，等待时间比较长。

执行该命令后，nvidia/cuda:11.4.0-devel镜像被下载到本地，可以查看已经下载的镜像。

```sh
sudo docker images
```

以下命令，启动并进入名为develop的，基于cuda-11.4.0-devel镜像的docker容器

将develop容器的home文件夹，映射到主机文件夹/home/ubuntu

端口映射关系：容器develop的22端口映射到主机的224

```sh
sudo docker run -it --ipc=host --gpus all -v /home/ubuntu --restart=always --name develop -p 6006:6606 -p 1234:1234 -p 2333:2333 -p 224:22 -p 6666:6666 nvidia/cuda:11.4.0-devel
# 后台运行
ctrl+p+q
```

### 2.5 拉取/启动一个anaconda的docker容器

和cuda-devel镜像原理一样，注意在docker中创建jupyter容器的办法。

启动后浏览器输入

http://主机ip:8888

再填入返回的token即可使用jupyter

云服务器需要配置安全组策略:入站，0.0.0.0/0,允许TCP:8888

```sh
sudo docker pull continuumio/anaconda3
sudo docker images
# 启动一个普通的可以运行python的环境
sudo docker run -it --name="anaconda" -p 8888:8888 continuumio/anaconda3 /bin/bash
# 启动一个运行jupyter的容器
sudo docker run -i -t -p 8888:8888 continuumio/anaconda3 /bin/bash -c "/opt/conda/bin/conda install jupyter -y --quiet && mkdir /opt/notebooks && /opt/conda/bin/jupyter notebook --notebook-dir=/opt/notebooks --ip='*' --port=8888 --no-browser --allow-root"
```

## 3. 安装k8s软件
**此步骤，master和worker机器上操作一样**
### 3.1 设置签名秘钥
从非标准库例如阿里云、腾讯云的镜像中拉取的二进制包，必须确保软件是真的，所以需要进行这一步骤，否则报错为：
```
W: GPG error: https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial InRelease: The
following signatures couldn’t be verified because the public key is not available: NO_PUBKEY
FEEA9169307EA071 NO_PUBKEY 8B57C5C2836F4BEB
W: The repository ‘https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial InRelease’ is
not signed.
N: Data from such a repository can’t be authenticated and is therefore potentially
dangerous to use.
N: See apt-secure(8) manpage for repository creation and user configuration details
```

```sh
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg |sudo apt-key add -
```

在每个节点主机上，都要使用 curl 命令下载密钥，然后将其存储在安全的位置，默认为/usr/share/keyrings

### 3.2 设置k8s源
Kubernetes 不包含在默认存储库中。要将 Kubernetes 存储库添加到列表中。否则在执行
```sh
apt-get install kubeadm kubectl kubelet -y
```
时会出现以下报错：
```
No apt package “kubeadm”, but there is a snap with that name.
Try “snap install kubeadm”
No apt package “kubectl”, but there is a snap with that name.
Try “snap install kubectl”
No apt package “kubelet”, but there is a snap with that name.
Try “snap install kubelet”
```

编辑源仓库，加入一行k8s源：
```sh
sudo echo -e "deb https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial main" >> /etc/apt/sources.list
```

更新源
```sh
sudo apt-get update
```

### 3.3 安装k8s软件
Kubeadm（Kubernetes Admin）是一个帮助初始化集群的工具。它通过使用社区来源的最佳实践来快速跟踪设置。Kubelet 是工作包，它在每个节点上运行并启动容器。该工具提供对群集的命令行访问权限。

```sh
sudo apt install kubeadm=1.23.6-00 kubelet=1.23.6-00 kubectl=1.23.6-00 -y
```

注意：
1. 集群中master和worker的版本必须保持一致，否则可能出现难以预料的后果。
2. 这里必须安装1.24以下的版本，k8s自1.24开始不再支持docker，否则后续实验无法完成。

使用该命令，锁定k8s工具链软件版本不更新。

```sh
sudo apt-mark hold kubeadm kubelet kubectl
```

验证安装：
```sh
kubeadm version
kubelet --version
kubectl version --client
```

## 4. 部署集群的网络准备
**此步骤，除了设置主机名和内网IP填写的具体值，master和worker机器上操作一样**
### 4.1 禁用交换内存
```sh
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

### 4.2 设置容器模块并添加
```sh
sudo echo -e "overlay" >> /etc/modules-load.d/containerd.conf
sudo echo -e "br_netfilter" >> /etc/modules-load.d/containerd.conf
sudo modprobe overlay
sudo modprobe br_netfilter
```

### 4.3 配置k8s网络并重新加载系统网络设置
```sh
sudo echo -e "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.d/kubernetes.conf
sudo echo -e "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/kubernetes.conf
sudo echo -e "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/kubernetes.conf
sudo sysctl --system
```

### 4.4 设置每一结点的主机名
使用的是腾讯云内网IP，同内网IP需要买同一个地域分区的，我买了南京3区，内网网段10.206.0.0/16
对于master:
```sh
sudo hostnamectl set-hostname master
```
对于worker:
```sh
sudo hostnamectl set-hostname worker01
```

在每一主机上编辑内往网段主机IP映射表
```sh
sudo vim /etc/hosts
```

写法：127.0.1.1 绑定本机主机名，再写出集群中包括自己的所有master和node的腾讯云内网IP。

例如以下是一个3机集群，master的内网IP为10.206.0.10，worker01的的内网IP为10.206.0.9，worker02的的内网IP为10.206.0.11

master-node：

```
127.0.0.1 localhost
127.0.1.1 master-node
10.206.0.10 master-node
10.206.0.9 worker01
10.206.0.11 worker02
```

worker01：

```
127.0.0.1 localhost
127.0.1.1 worker01
10.206.0.10 master-node
10.206.0.9 worker01
10.206.0.11 worker02
```

worker02：

```
127.0.0.1 localhost
127.0.1.1 worker02
10.206.0.10 master-node
10.206.0.9 worker01
10.206.0.11 worker02
```

### 4.5 关闭防火墙
```sh
sudo apt install selinux-utils
sudo setenforce 0
sudo systemctl disable firewalld
```

## 5. master上初始化集群
**此步骤只在master上进行**
### 5.1 初始化kubelet设置
```sh
sudo echo -e "KUBELET_EXTRA_ARGS=\"--cgroup-driver=systemd\"" >> /etc/default/kubelet
sudo echo -e "KUBELET_EXTRA_ARGS=\"--cgroup-driver=cgroupfs\"" >> /etc/default/kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

### 5.2 添加docker配置
修改docker配置文件，添加以下内容在最外层，注意保持格式。

```sh
sudo vi /etc/docker/daemon.json
```

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
```

重新启动docker。
```sh
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### 5.3 初始化kubedeam

```sh
sudo echo -e "Environment=\"KUBELET_EXTRA_ARGS=--fail-swap-on=false\"" >> /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

### 5.4 初始化集群
master上初始化集群命令如下：
```sh
kubeadm init --apiserver-advertise-address=10.206.0.10 \
        --apiserver-cert-extra-sans=127.0.0.1 \
        --pod-network-cidr=10.244.0.0/16 \
        --image-repository=registry.aliyuncs.com/google_containers
```

注意pod-network-cidr不是内网网段，如果更改，后续手动下载kube-fannel.yml到本地同步更改。

如果初始化失败，先尝试reset。
```sh
kubeadm reset
```

初始化成功后，可以拿到node加入集群的token：
```sh
kubeadm join 10.206.0.10:6443 --token bo8anf.j1lyyn1nffpirarh \
        --discovery-token-ca-cert-hash sha256:32e8a8f86f9dd339b1ce46aea3fdb47b1451a763a653475bc53d45dbec97b5d8 
```

master上还需要创建集群目录：
```sh
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

master上也需要配置环境变量：
```sh
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile
source ~/.bash_profile
```

注意，token是有有效期的，一般为5分钟。
如果后续还有node结点加入集群失败，可以在master上重新生成新的token。

先生成token后打印join命令：

```sh
root@master-node:/home/ubuntu# kubeadm token generate
k0t62m.6m6nbwpc9yecl7ik
root@master-node:/home/ubuntu# kubeadm token create k0t62m.6m6nbwpc9yecl7ik  --print-join-command --ttl=0
kubeadm join 10.206.0.10:6443 --token k0t62m.6m6nbwpc9yecl7ik --discovery-token-ca-cert-hash sha256:32e8a8f86f9dd339b1ce46aea3fdb47b1451a763a653475bc53d45dbec97b5d8 
```

一步生成新token打印join命令：
```sh
kubeadm token create --print-join-command
```

在master上查看集群master详细信息：
```sh
kubectl describe node master-node
```

### 5.6 配置flanne虚拟网桥
此命令在master完成init后执行，执行后master才能找到node，否则node加入成功后，master上node的状态为unReady。

如果node状态还是unReady，那么在node上也按照如下步骤配置网桥。

```sh
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

如果长时间无响应，应该是github无法访问，可以爬取到本地文件再执行。

执行后，docker中有两个flannel镜像容器

```sh
docker images | grep flannel
```

可以看到两个镜像：
```
flannel/flannel                                      v0.21.4        11ae74319a21   2 weeks ago     64.1MB
flannel/flannel-cni-plugin                           v1.1.2         7a2dcab94698   4 months ago    7.97MB
```

如果没有，手动拉取：
```sh
docker pull flannel/flannel:v0.21.4
docker pull flannel/flannel-cni-plugin:v1.1.2
```

## 6. node上加入集群

### 6.1 sftp传输文件
将master上/etc/kubernetes/admin.conf文件，复制到node上面同一个位置，注意传输前后改文件所有用户。

### 6.2 加入环境变量
```sh
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile
source ~/.bash_profile
```

### 6.3 join集群
运行master上拿到的join命令。
```sh
kubeadm join 10.206.0.10:6443 --token k0t62m.6m6nbwpc9yecl7ik --discovery-token-ca-cert-hash sha256:32e8a8f86f9dd339b1ce46aea3fdb47b1451a763a653475bc53d45dbec97b5d8 
```

提示可以在master上get，则说明已经加入集群，但未必Ready。
```sh
kubectl get nodes
```

### 6.4 常见的join失败的排查方法
#### 6.4.1 重启kubeadm
针对[preflight]阶段的报错，在node上重启kubeadm是最好的办法，重启后选yes。
```sh
kubeadm reset
```

reset后，一般会提示还需要用户手动删除网络配置目录。
```sh
rm -rf /etc/cni/net.d
ipvsadm --clear
```

然后再重新join。

#### 6.4.2 检查docker/kubelet
主要针对如下报错：
```
[kubelet-check] The HTTP call equal to 'curl -sSL http://localhost:10248/healthz' failed with error: Get "http://localhost:10248/healthz": dial tcp 127.0.0.1:10248: connect: connection refused.
[kubelet-check] It seems like the kubelet isn't running or healthy.
```

该报错主要是docker或kubelet状态异常，或它们的参数有不匹配之处（比如CGroup Driver）。

检查docker配置文件是否被默认修改，如果改动的话重启docker。
```sh
cat /etc/docker/daemon.json
sudo systemctl daemon-reload
sudo systemctl restart docker
```

检查kubelet配置文件，如果有问题的的话重启。

#### 6.4.3 检查网络
检查端口安全组设置。

检查防火墙是不是关闭。
```sh
sudo apt install selinux-utils
sudo setenforce 0
sudo systemctl disable firewalld
```

更新iptables。
```sh
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
```

#### 6.4.4 检查token是否过期
如果join长时间无反应，一般是token过期，master上重新获取token。

#### 6.4.5 检查环境变量
```sh
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile
source ~/.bash_profile
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

每次更换admin.conf文件后，环境变量要重新加载。

如果master上使用kubectl命令无响应或以下两种报错，也检查环境变量。

```
The connection to the server 172.17.0.8:6443 was refused - did you specify the right host or port?
```

```
Unable to connect to the server: x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "kubernetes")
```

### 6.5 常见的node在master上状态为unReady的排查方法
#### 6.5.1 检查flanne虚拟网桥
针对以下原因：
```txt
Container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:docker: network plugin is not ready: cni config uninitialized
```

一般每一次master上init集群后，都要在master上配置。
一般成功Ready后，两个flannel容器会被复制到node上，不用在node上再配置。
但是如果还是unReady，在node上也配置，方法见上文。

#### 6.5.2 检查node的配置
检查/etc/kubernetes/admin.conf文件是否存在和上文中设置的环境变量是否正确。
**注意，master上变更该文件后，复制到node上，需要重新source配置文件**
**在master上重新init集群，或者在node上kubeadm reset会删除该文件**

#### 6.5.3 直接获得node状态unReady原因
使用describe命令，直接查询node状态，一般会有提示。
```sh
kubectl describe node worker02
```

#### 6.5.4 重新初始化整个集群
如果以上方法都无效，建议master上重新初始化整个集群。
注意改动admin.conf，生成集群目录，node上更新admin.conf和source配置。
然后还要重新配flannel。

## 7. 集群上删除某一node
### 7.1 master上删除node
先查看一下这个node节点上的pod信息
```sh
kubectl get nodes
```
强制驱逐这个node节点上的pod
```sh
kubectl drain worker01 --delete-local-data --force --ignore-daemonsets
```
在集群中删除这个node节点 
```sh
kubectl delete nodes worker01
```

### 7.2 node上删除配置
否则导致重新加入集群时出错
```sh
kubeadm reset
systemctl stop kubelet
systemctl stop docker
rm -rf /var/lib/cni/
rm -rf /var/lib/kubelet/*
rm -rf /etc/cni/
ifconfig cni0 down
ifconfig flannel.1 down
ifconfig docker0 down
ip link delete cni0
ip link delete flannel.1
systemctl start docker
systemctl start kubelet
```

## 8. 安装配置k8s Dashboard
```
cat > /etc/kubernetes/manifests/recommended.yaml << EOF
# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

apiVersion: v1
kind: Namespace
metadata:
  name: kubernetes-dashboard

---

apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard

---

kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  type: NodePort #新添加的，下面有一个删除了，注意缩进了2个空格
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 30001 #新添加的
  selector:
    k8s-app: kubernetes-dashboard

---

apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-certs
  namespace: kubernetes-dashboard
type: Opaque

---

apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-csrf
  namespace: kubernetes-dashboard
type: Opaque
data:
  csrf: ""

---

apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-key-holder
  namespace: kubernetes-dashboard
type: Opaque

---

kind: ConfigMap
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-settings
  namespace: kubernetes-dashboard

---

kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
rules:
  # Allow Dashboard to get, update and delete Dashboard exclusive secrets.
  - apiGroups: [""]
    resources: ["secrets"]
    resourceNames: ["kubernetes-dashboard-key-holder", "kubernetes-dashboard-certs", "kubernetes-dashboard-csrf"]
    verbs: ["get", "update", "delete"]
    # Allow Dashboard to get and update 'kubernetes-dashboard-settings' config map.
  - apiGroups: [""]
    resources: ["configmaps"]
    resourceNames: ["kubernetes-dashboard-settings"]
    verbs: ["get", "update"]
    # Allow Dashboard to get metrics.
  - apiGroups: [""]
    resources: ["services"]
    resourceNames: ["heapster", "dashboard-metrics-scraper"]
    verbs: ["proxy"]
  - apiGroups: [""]
    resources: ["services/proxy"]
    resourceNames: ["heapster", "http:heapster:", "https:heapster:", "dashboard-metrics-scraper", "http:dashboard-metrics-scraper"]
    verbs: ["get"]

---

kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
rules:
  # Allow Metrics Scraper to get metrics from the Metrics server
  - apiGroups: ["metrics.k8s.io"]
    resources: ["pods", "nodes"]
    verbs: ["get", "list", "watch"]

---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: kubernetes-dashboard
subjects:
  - kind: ServiceAccount
    name: kubernetes-dashboard
    namespace: kubernetes-dashboard

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kubernetes-dashboard
subjects:
  - kind: ServiceAccount
    name: kubernetes-dashboard
    namespace: kubernetes-dashboard

---

kind: Deployment
apiVersion: apps/v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: kubernetes-dashboard
  template:
    metadata:
      labels:
        k8s-app: kubernetes-dashboard
    spec:
      containers:
        - name: kubernetes-dashboard
          image: kubernetesui/dashboard:v2.0.0
          imagePullPolicy: Always
          ports:
            - containerPort: 8443
              protocol: TCP
          args:
            - --auto-generate-certificates
            - --namespace=kubernetes-dashboard
            # Uncomment the following line to manually specify Kubernetes API server Host
            # If not specified, Dashboard will attempt to auto discover the API server and connect
            # to it. Uncomment only if the default does not work.
            # - --apiserver-host=http://my-address:port
          volumeMounts:
            - name: kubernetes-dashboard-certs
              mountPath: /certs
              # Create on-disk volume to store exec logs
            - mountPath: /tmp
              name: tmp-volume
          livenessProbe:
            httpGet:
              scheme: HTTPS
              path: /
              port: 8443
            initialDelaySeconds: 30
            timeoutSeconds: 30
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            runAsUser: 1001
            runAsGroup: 2001
      volumes:
        - name: kubernetes-dashboard-certs
          secret:
            secretName: kubernetes-dashboard-certs
        - name: tmp-volume
          emptyDir: {}
      serviceAccountName: kubernetes-dashboard
      nodeSelector:
        "kubernetes.io/os": linux
      # Comment the following tolerations if Dashboard must not be deployed on master
      tolerations:
        - key: node-role.kubernetes.io/master
          effect: NoSchedule

---

kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: dashboard-metrics-scraper
  name: dashboard-metrics-scraper
  namespace: kubernetes-dashboard
spec:
  ports:
    - port: 8000
      targetPort: 8000
  selector:
    k8s-app: dashboard-metrics-scraper

---

kind: Deployment
apiVersion: apps/v1
metadata:
  labels:
    k8s-app: dashboard-metrics-scraper
  name: dashboard-metrics-scraper
  namespace: kubernetes-dashboard
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: dashboard-metrics-scraper
  template:
    metadata:
      labels:
        k8s-app: dashboard-metrics-scraper
      annotations:
        seccomp.security.alpha.kubernetes.io/pod: 'runtime/default'
    spec:
      containers:
        - name: dashboard-metrics-scraper
          image: kubernetesui/metrics-scraper:v1.0.4
          ports:
            - containerPort: 8000
              protocol: TCP
          livenessProbe:
            httpGet:
              scheme: HTTP
              path: /
              port: 8000
            initialDelaySeconds: 30
            timeoutSeconds: 30
          volumeMounts:
          - mountPath: /tmp
            name: tmp-volume
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            runAsUser: 1001
            runAsGroup: 2001
      serviceAccountName: kubernetes-dashboard
      nodeSelector:
        "kubernetes.io/os": linux
      # Comment the following tolerations if Dashboard must not be deployed on master
      tolerations:
        - key: node-role.kubernetes.io/master
          effect: NoSchedule
      volumes:
        - name: tmp-volume
          emptyDir: {}
EOF

```

```
cat > metrics-server.yaml << EOF
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:aggregated-metrics-reader
  labels:
    rbac.authorization.k8s.io/aggregate-to-view: "true"
    rbac.authorization.k8s.io/aggregate-to-edit: "true"
    rbac.authorization.k8s.io/aggregate-to-admin: "true"
rules:
- apiGroups: ["metrics.k8s.io"]
  resources: ["pods", "nodes"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: metrics-server:system:auth-delegator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: metrics-server-auth-reader
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: extension-apiserver-authentication-reader
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
apiVersion: apiregistration.k8s.io/v1
kind: APIService
metadata:
  name: v1beta1.metrics.k8s.io
spec:
  service:
    name: metrics-server
    namespace: kube-system
  group: metrics.k8s.io
  version: v1beta1
  insecureSkipTLSVerify: true
  groupPriorityMinimum: 100
  versionPriority: 100
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-server
  namespace: kube-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-server
  namespace: kube-system
  labels:
    k8s-app: metrics-server
spec:
  selector:
    matchLabels:
      k8s-app: metrics-server
  template:
    metadata:
      name: metrics-server
      labels:
        k8s-app: metrics-server
    spec:
      serviceAccountName: metrics-server
      volumes:
      # mount in tmp so we can safely use from-scratch images and/or read-only containers
      - name: tmp-dir
        emptyDir: {}
      containers:
      - name: metrics-server
        image: lizhenliang/metrics-server:v0.3.7 
        imagePullPolicy: IfNotPresent
        args:
          - --cert-dir=/tmp
          - --secure-port=4443
          - --kubelet-insecure-tls
          - --kubelet-preferred-address-types=InternalIP
        ports:
        - name: main-port
          containerPort: 4443
          protocol: TCP
        securityContext:
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
        volumeMounts:
        - name: tmp-dir
          mountPath: /tmp
      nodeSelector:
        kubernetes.io/os: linux
        kubernetes.io/arch: "amd64"
---
apiVersion: v1
kind: Service
metadata:
  name: metrics-server
  namespace: kube-system
  labels:
    kubernetes.io/name: "Metrics-server"
    kubernetes.io/cluster-service: "true"
spec:
  selector:
    k8s-app: metrics-server
  ports:
  - port: 443
    protocol: TCP
    targetPort: main-port
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:metrics-server
rules:
- apiGroups:
  - ""
  resources:
  - pods
  - nodes
  - nodes/stats
  - namespaces
  - configmaps
  verbs:
  - get
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:metrics-server
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:metrics-server
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
EOF
```

创建DashBoard。
```sh
kubectl apply -f metrics-server.yaml
kubectl apply -f recommended.yaml
```

等待dashboard的pod处于Running。

```sh
kubectl get pods -A | grep dashboard
```

用Firefox浏览器访问：
https://<master ip>:30001
选择“高级”

Chrome和Edge不行。

```sh
# 创建用户
kubectl create serviceaccount dashboard-admin -n kube-system
# 用户授权
kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
# 获取用户Token
kubectl describe secrets -n kube-system $(kubectl -n kube-system get secret | awk '/dashboard-admin/{print $1}') #
```

## 9. 安装helm
在github上helm的版本日志有各个版本的下载，选择3.10.3
地址：https://get.helm.sh/helm-v3.10.3-linux-amd64.tar.gz
解压后，将helm复制到/usr/local/bin目录中，chmod +x

## 10. 安装配置第四范式vGPU插件
### 10.1 检查docker配置文件
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

### 10.2 设置集群中有GPU的服务器可以被调度到
master上给结点打上gpu可用的标签
```sh
kubectl label nodes {nodeid} gpu=on
```

如果要让master同时参与pod分配调度，需要额外的一些设置，见10.5。

### 10.3 安装插件
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

### 10.4 使用插件部署一个使用限定GPU资源的pod
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

### 10.5 监控vGPU使用情况
调度器部署成功后，监控默认自动开启，可以通过
```url
http://{nodeip}:{monitorPort}/metrics
```
来获取监控数据，其中monitorPort可以在Values中进行配置，默认为31992
注意，节点上的vGPU状态只有在其使用vGPU后才会被统计

### 10.5 设置master可以参与pod调度
Unschedulable表示节点是否参与pod调度，master默认情况下为false。

```sh
kubectl describe node master-node
```
```
Taints:             node-role.kubernetes.io/master:NoSchedule
Unschedulable:      false
```

首先，去掉master不参与pod调度的污点（taint）
```sh
kubectl taint nodes master-node node-role.kubernetes.io/master-
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
kubectl taint nodes master-node node-role.kubernetes.io/master=:NoSchedule
```

将master上已经存在的Pod驱逐出去的命令：
```sh
kubectl taint nodes master-node node-role.kubernetes.io/master=:NoExecute
```


## 11. 使用CGroupfs作为Docker和Kubelet的CGroup Driver

Docker默认CGroup Driver是cgroupfs，k8s默认CGroup Driver是systemd，要保持二者一致才能正常使用。

注意，Docker和Linux内核支持cgroupfs v2较早，但k8s在1.25起才稳定支持cgroupfs v2，低版本时使用的其实是v1。

### 11.1 Dcoker启用cgroupfs
```sh
vi /etc/docker/daemon.json
```

```json
 "exec-opts": [ "native.cgroupdriver=cgroupfs" ],
```

```sh
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### 11.2 kubelet启用cgroupfs
在kubelet服务的主配置文件中修改，也可以把字段写到附加参数文件。
```sh
vi /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
```

```conf
# Note: This dropin only works with kubeadm and kubelet v1.11+
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
# This is a file that "kubeadm init" and "kubeadm join" generates at runtime, populating the KUBELET_KUBEADM_ARGS variable dynamically
EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env
# This is a file that the user can use for overrides of the kubelet args as a last resort. Preferably, the user should use
# the .NodeRegistration.KubeletExtraArgs object in the configuration files instead. KUBELET_EXTRA_ARGS should be sourced from this file.
EnvironmentFile=-/etc/default/kubelet
ExecStart=
ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS
Environment="KUBELET_EXTRA_ARGS=--fail-swap-on=false --docker-endpoint=unix:///var/run/koord-runtimeproxy/runtimeproxy.sock"
```

包括后面koord-runtime-proxy需要设置的socket参数也写在这里。

```sh
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

### 11.3 系统内核启动cgroupfs v2
参考资料: 
http://www.taodudu.cc/news/show-3209270.html
https://blog.csdn.net/easylife206/article/details/128747838

适用于Ubuntu Server 18.04, 20.04 LTS

判断系统是否启用了cgroups v2：

```sh
cat /sys/fs/cgroup/cgroup.controllers
```

如果提示not found，说明是v1. 若已启用v2则会打印出生效中的控制器，例如

```
cpuset cpu io memory pids rdma
```

调整grub linux内核引导参数：

```sh
sudo vim /etc/default/grub
```

在GRUB_CMDLINE_LINUX一行添加：
```
systemd.unified_cgroup_hierarchy=1
```

保存退出后，更新grub:

```sh
sudo update-grub
sudo reboot
```

重启后系统将使用cgroups v2作为默认控制器。

注意：参数添加在不同未知的区别：
GRUB_CMDLINE_LINUX_DEFAULT 仅在正常引导时才有效（恢复模式不适用）
GRUB_CMDLINE_LINUX 总是有效的

## 12. 安装配置Koordinator
### 12.1 安装Koordinator
如果能连上github：
```sh
helm repo add koordinator-sh https://koordinator-sh.github.io/charts/
helm repo update
helm install koordinator koordinator-sh/koordinator --version 1.2.0
```

如果连不上github：
```sh
helm install koordinator https://github.com/koordinator-sh/charts/releases/download/koordinator-1.2.0/koordinator-1.2.0.tgz --set imageRepositoryHost=registry.cn-beijing.aliyuncs.com
```

### 12.2 安装koord-runtime-proxy
注意与koordinator版本保持一致
```sh
wget https://github.com/koordinator-sh/koordinator/releases/download/v1.2.0/koord-runtime-proxy_1.2.0_linux_x86_64 -O koord-runtime-proxy
chmod +x koord-runtime-proxy
cp -f koord-runtime-proxy /usr/local/bin/
koord-runtime-proxy --help
```

### 12.3 配置koord-runtime-proxy
需要docker和kubelet的CGroup Driver均设置为cgroupfs，设置方法另附。
原理是代理转发cgroup driver到Docker的请求，使用Koordinator代替kubelet调度器做资源扩缩容的调度。

开启Docker socker监听：

```sh
koord-runtime-proxy --backend-runtime-mode=Docker --remote-runtime-service-endpoint=/var/run/docker.sock
```

### 12.4 卸载
```sh
helm uninstall koordinator
```

```
release "koordinator" uninstalled
```

## 13. k8s安装配置Prometheus
### 13.1 下载kube-prometheus包安装
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

### 13.2 查看监控组件信息
查看CRD类型。
```sh
kubectl get crd | grep coreos
```

查看特定CRD类型下实例。
```sh
kubectl get prometheuses -n monitoring
kubectl get servicemonitors -n monitoring
```

查看创建的service。
```sh
kubectl get svc -n monitoring
```

查询monitoring命名空间所有组件的状态。
```sh
kubectl get po -n monitoring
```

查询非Running状态pod的方法，可以获得容器启动失败的原因。
```sh
kubectl describe  po prometheus-adapter-7858d4ddfd-55lnq  -n monitoring
```

### 13.3 解决组件所需镜像 ImagePullBackOff / ErrImageNeverPull
参考：https://blog.csdn.net/qq_45439217/article/details/123477846
#### 13.3.1 prometheus-adapter
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

#### 13.3.2 kube-state-metrics
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

### 13.4 配置外网访问
方法是使用kubectl edit修改三者的service配置。为端口增加nodePort字段作为外网转发端口，将type字段的值从ClusterIp改为NodePort

#### 13.4.1 prometheus

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

#### 13.4.2 grafana

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

#### 13.4.2 alertmanager

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

#### 13.4.5 使用方法
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

## 14. GPU插件nvidia_gpu_exporter配置
### 14.1 下载安装
多种安装方式：
https://github.com/utkuozdemir/nvidia_gpu_exporter/blob/master/INSTALL.md
推荐使用静态deb包安装。

安装完成后，可以查看命令。
```sh
nvidia_gpu_exporter --help
```

### 14.2 配置系统服务
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

### 14.3 在k8s集群中用helm安装
官方chart:
https://artifacthub.io/packages/helm/utkuozdemir/nvidia-gpu-exporter

安装:
```sh
helm repo add utkuozdemir https://utkuozdemir.org/helm-charts
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

### 14.4 将数据接入prometheus
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

## 15. NVIDIA DCGM安装使用
NVIDIA DCGM是采集GPU监控数据的软件。
### 15.1 安装并配置服务
```sh
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb
sudo dpkg -i cuda-keyring_1.0-1_all.deb
sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /"
sudo apt-get update && sudo apt-get install -y datacenter-gpu-manager
sudo systemctl --now enable nvidia-dcgm
sudo systemctl status nvidia-dcgm
```

### 15.2 在helm上安装并将数据接入prometheus
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

### 15.3 卸载
```sh
kubectl delete daemonset dcgm-exporter-1684277642  -n monitoring
kubectl delete service dcgm-exporter-1684277642  -n monitoring
```

## 16. Go语言环境
以安装1.17.9为例（和k8s使用的go版本一致），解压后设置环境变量即可。

```sh
wget https://dl.google.com/go/go1.17.9.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.17.9.linux-amd64.tar.gz
sudo echo -e "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile
source /etc/profile
go version
```
