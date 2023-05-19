#!/bin/bash
wget https://mirrors.nju.edu.cn/golang/go1.20.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.20.linux-amd64.tar.gz
sudo echo -e "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile
source /etc/profile
rm -f go1.20.linux-amd64.tar.gz
go version
