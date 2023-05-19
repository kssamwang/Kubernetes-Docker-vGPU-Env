#!/bin/bash
# 1 ����ǩ����Կ
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg |sudo apt-key add -
# 2 ����k8sԴ
sudo echo -e "deb https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial main" >> /etc/apt/sources.list
sudo apt-get update
# 3 ��װk8s���
sudo apt install kubeadm=1.23.6-00 kubelet=1.23.6-00 kubectl=1.23.6-00 -y
sudo apt-mark hold kubeadm kubelet kubectl
kubeadm version
kubelet --version
kubectl version --client