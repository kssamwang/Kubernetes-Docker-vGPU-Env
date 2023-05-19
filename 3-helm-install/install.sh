#!/bin/bash
wget https://mirrors.huaweicloud.com/helm/v3.10.3/helm-v3.10.3-linux-amd64.tar.gz
tar -xzvf helm-v3.10.3-linux-amd64.tar.gz
chown root:root ./linux-amd64/helm
cp -f ./linux-amd64/helm /usr/local/bin/helm
rm -rf helm-v3.10.3-linux-amd64.tar.gz ./linux-amd64
helm version

