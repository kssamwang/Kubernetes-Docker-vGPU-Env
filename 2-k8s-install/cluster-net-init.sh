#!/bin/bash
# 0 真真真 ./networktools-install.sh
# 1 真真真
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
# 2 真真真真�
sudo echo -e "overlay" >> /etc/modules-load.d/containerd.conf
sudo echo -e "br_netfilter" >> /etc/modules-load.d/containerd.conf
sudo modprobe overlay
sudo modprobe br_netfilter
# 3 真k8s真真真真真真�
sudo echo -e "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.d/kubernetes.conf
sudo echo -e "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/kubernetes.conf
sudo echo -e "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/kubernetes.conf
sudo sysctl --system
# 4 真真真真真
# 5 真真�
sudo setenforce 0
sudo systemctl disable firewalld

