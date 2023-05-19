#!/bin/bash
if [ $# -ne 1 ] ; then
        echo "wrong argument [worker node name]"
        exit
else
        echo "worker node name : $1"
fi

sudo mkdir -p /etc/docker/certs.d
sudo openssl genrsa -out /etc/docker/certs.d/$1:443.key 4096
sudo openssl req -subj '/CN=$1' -new -key /etc/docker/certs.d/$1:443.key -out /etc/docker/certs.d/$1:443.csr
sudo openssl x509 -req -days 365 -in /etc/docker/certs.d/$1:443.csr -CA /tls/ca.pem -CAkey /tls/ca-key.pem -CAcreateserial -out /etc/docker/certs.d/$1:443.crt -extfile /tls/extfile.cnf
mkdir -p /etc/docker/certs.d/$1:443/
cp -f /tls/ca.pem /etc/docker/certs.d/$1:443/ca.crt
cp -f /tls/server-key.pem /etc/docker/certs.d/$1:443/server.key
cp -f /tls/server-cert.pem /etc/docker/certs.d/$1:443/server.crt
sudo systemctl stop docker
cp -f docker.service /lib/systemd/system/docker.service
sudo systemctl daemon-reload
sudo systemctl start docker
sudo systemctl restart kubelet

