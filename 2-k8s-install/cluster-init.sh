#!/bin/bash
# 部署集群的网络准备，此步骤master和worker一样
# 1 禁用交换内存
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
# 2 设置容器模块并添加
sudo echo -e "overlay" >> /etc/modules-load.d/containerd.conf
sudo echo -e "br_netfilter" >> /etc/modules-load.d/containerd.conf
sudo modprobe overlay
sudo modprobe br_netfilter
# 3 配置k8s网络并重新加载系统网络设置
sudo echo -e "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.d/kubernetes.conf
sudo echo -e "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/kubernetes.conf
sudo echo -e "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/kubernetes.conf
sudo sysctl --system
# 4 设置每一结点的主机名
# 5 关闭防火墙
sudo apt install selinux-utils
sudo setenforce 0