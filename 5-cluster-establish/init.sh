#!/bin/bash
masterip=$(ifconfig eth0 | egrep "inet [0-9]+.[0-9]+.[0-9]+.[0-9]+" | awk '{ print $2 }')
echo "k8s cluster init .... master host ip $masterip"
kubeadm init --apiserver-advertise-address=$masterip --apiserver-cert-extra-sans=127.0.0.1 --pod-network-cidr=10.244.0.0/16 --image-repository=registry.aliyuncs.com/google_containers
