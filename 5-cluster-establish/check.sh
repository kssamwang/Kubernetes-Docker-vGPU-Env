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
