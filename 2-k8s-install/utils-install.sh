#!/bin/bash
# 安装firewalld/ipvsadm
sudo apt install ipvsadm -y
sudo apt-get install firewalld -y
sudo apt install selinux-utils -y
sudo setenforce 0
sudo systemctl disable firewalld
