#!/bin/bash
# 部署集群的网络准备，此步骤master和worker一样
# 0 先安装了网络工具 ./utils-install.sh
# 1 禁用内存交换
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
# 4 设置主机名
# sudo hostnamectl set-hostname
# vi /etc/hosts
# <集群中每一个node的hostname>  <集群中每一个node的内网ip> 
# 5 关闭防火墙
sudo setenforce 0
sudo systemctl disable firewalld
