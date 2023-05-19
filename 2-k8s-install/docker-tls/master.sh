#!/bin/bash
if [ $# -ne 2 ] ; then
	echo "wrong argument [worker node name] [worker node ip]"
	exit
else
	echo "worker node name : $1"
	echo "worker node ip   : $2"
fi

if [ ! -d "/tls" ] || [ ! -f "/tls/ca-key.pem" ] || [ ! -f "/tls/ca.pem" ];then
	mkdir -p /tls && cd /tls
	# 1. 创建CA证书
	openssl genrsa -out ca-key.pem 4096
	openssl req -new -x509 -days 365 -key ca-key.pem -out ca.pem
fi

# 2. 使用SAN证书
mkdir -p /tls/$1 && cd /tls/$1
openssl genrsa -out server-key.pem 4096
openssl req -new -key server-key.pem -subj "/CN=$1" -out server.csr
mkdir -p /tls/$1/certs && cd /tls/$1/certs
echo subjectAltName = DNS:$1,IP:$2 > /tls/$1/certs/extfile.cnf
# 3. 签名证书
cd /tls/$1
openssl x509 -req -days 365 -in server.csr -CA ../ca.pem -CAkey ../ca-key.pem -CAcreateserial -out server-cert.pem -extfile certs/extfile.cnf
# 4. 分发证书
scp /tls/ca.pem /tls/ca-key.pem /tls/$1/certs/extfile.cnf /tls/$1/server-key.pem /tls/$1/server-cert.pem ubuntu@$1:/tls

