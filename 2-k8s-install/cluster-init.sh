#!/bin/bash
# ����Ⱥ������׼�����˲���master��workerһ��
# 1 ���ý����ڴ�
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
# 2 ��������ģ�鲢���
sudo echo -e "overlay" >> /etc/modules-load.d/containerd.conf
sudo echo -e "br_netfilter" >> /etc/modules-load.d/containerd.conf
sudo modprobe overlay
sudo modprobe br_netfilter
# 3 ����k8s���粢���¼���ϵͳ��������
sudo echo -e "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.d/kubernetes.conf
sudo echo -e "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/kubernetes.conf
sudo echo -e "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/kubernetes.conf
sudo sysctl --system
# 4 ����ÿһ����������
# 5 �رշ���ǽ
sudo apt install selinux-utils
sudo setenforce 0