# ���������cuda�汾
nvidia-smi
nvcc -V
# ����Ƿ�����cgroupfs v2
cat /sys/fs/cgroup/cgroup.controllers
# ���docker��װ�����Ƿ������������ļ�master��worker��һ��
docker version
docker info | grep Cgroup
systemctl status docker
cat /etc/docker/daemon.json
# ���k8s�Ƿ�װ��ȷ�汾
kubeadm version
kubelet --version
kubectl version --client
# ������޽����ڴ棬swap��Ӧ��ȫ��Ϊ��
free -m
# ������ǽ�Ƿ�ر�
systemctl ststus firewalld
# �������Ⱥ����������������IP��Ӧ��
cat /etc/hosts
