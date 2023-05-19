# Kubernetes-Docker-vGPU-Env

## 0. 运行检查

```sh
# 检查驱动，cuda版本
nvidia-smi
nvcc -V
# 检查是否启用cgroupfs v2
cat /sys/fs/cgroup/cgroup.controllers
# 检查docker安装配置是否正常，配置文件master和worker不一致
docker version
docker info | grep Cgroup
systemctl status docker
cat /etc/docker/daemon.json
# 检查k8s是否安装正确版本
kubeadm version
kubelet --version
kubectl version --client
# 检查有无交换内存，swap行应该全部为空
free -m
# 检查防火墙是否关闭
systemctl ststus firewalld
# 检查主机群网络主机名和内网IP对应表
cat /etc/hosts
```

## 1. master上初始化集群
**此步骤只在master上进行**
### 1.1 初始化kubelet设置
```sh
sudo echo -e "KUBELET_EXTRA_ARGS=\"--cgroup-driver=systemd\"" >> /etc/default/kubelet
sudo echo -e "KUBELET_EXTRA_ARGS=\"--cgroup-driver=cgroupfs\"" >> /etc/default/kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

### 1.2 添加docker配置
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

### 1.3 初始化kubedeam

```sh
sudo echo -e "Environment=\"KUBELET_EXTRA_ARGS=--fail-swap-on=false\"" >> /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

**使用9中脚本切换cgroupfs，可代替上述3步骤**

### 1.4 初始化集群
master上初始化集群命令如下：
```sh
kubeadm init --apiserver-advertise-address={master内网IP} \
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

### 1.6 配置flanne虚拟网桥
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

## 2. node上加入集群

### 2.1 sftp传输文件
将master上/etc/kubernetes/admin.conf文件，复制到node上面同一个位置，注意传输前后改文件所有用户。

### 2.2 加入环境变量
```sh
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile
source ~/.bash_profile
```

### 2.3 join集群
运行master上拿到的join命令。
```sh
kubeadm join 10.206.0.10:6443 --token k0t62m.6m6nbwpc9yecl7ik --discovery-token-ca-cert-hash sha256:32e8a8f86f9dd339b1ce46aea3fdb47b1451a763a653475bc53d45dbec97b5d8 
```

提示可以在master上get，则说明已经加入集群，但未必Ready。
```sh
kubectl get nodes
```

### 2.4 常见的join失败的排查方法
#### 2.4.1 重启kubeadm
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

#### 2.4.2 检查docker/kubelet
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

#### 2.4.3 检查网络
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

#### 2.4.4 检查token是否过期
如果join长时间无反应，一般是token过期，master上重新获取token。

#### 2.4.5 检查环境变量
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

### 2.5 常见的node在master上状态为unReady的排查方法
#### 2.5.1 检查flanne虚拟网桥
针对以下原因：
```txt
Container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:docker: network plugin is not ready: cni config uninitialized
```

一般每一次master上init集群后，都要在master上配置。

一般成功Ready后，两个flannel容器会被复制到node上，不用在node上再配置。

但是如果还是unReady，在node上也配置，方法见上文。

#### 2.5.2 检查node的配置
检查/etc/kubernetes/admin.conf文件是否存在和上文中设置的环境变量是否正确。

**注意，master上变更该文件后，复制到node上，需要重新source配置文件**

**在master上重新init集群，或者在node上kubeadm reset会删除该文件**

#### 2.5.3 直接获得node状态unReady原因
使用describe命令，直接查询node状态，一般会有提示。
```sh
kubectl describe node worker02
```

#### 2.5.4 重新初始化整个集群
如果以上方法都无效，建议master上重新初始化整个集群。

注意改动admin.conf，生成集群目录，node上更新admin.conf和source配置。

然后还要重新配flannel。

## 3. 集群上删除某一node
### 3.1 master上删除node
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

### 3.2 node上删除配置
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
