# Docker 启用tls连接

## 0. 环境

两台Linux服务器，都是Ubuntu20.04操作系统，Kubernetes v1.23.6，Docker 20.10.12。

Kubernetes集群的master节点IP地址10.206.16.6，主机名为“master”。

另一个工作节点IP地址10.206.16.12，主机名为“worker01”。

以下是为Docker配置tls使得master可以直接访问worker01上的docker server的步骤：

如果不想按步骤做，可以直接使用配置脚本：

### 0.1 在worker上操作

```sh
mkdir -p /tls
chown ubuntu:ubuntu /tls
```

### 0.2 在master上操作

```sh
./master.sh [worker node name] [worker node ip]
```

### 0.3 在worker上操作

```sh
./worker.sh [worker node name]
```



## 1. 创建CA证书
在master节点上使用openssl生成CA证书：
```sh
mkdir -p /tls && cd /tls
openssl genrsa -out ca-key.pem 4096
openssl req -new -x509 -days 365 -key ca-key.pem -out ca.pem
```

## 2. 使用SAN证书
在master节点上使用openssl生成SAN证书签名请求（CSR）：
```sh
mkdir -p /tls/worker01 && cd /tls/worker01
openssl genrsa -out server-key.pem 4096
openssl req -new -key server-key.pem -subj "/CN=worker01" -out server.csr
```

其中“worker01”是worker节点的主机名,10.206.16.12是其内网IP。


为了使用SAN证书，我们需要创建一个文件夹
并为该文件夹下的每个节点创建一个配置文件。
在这个例子中，我们将文件夹命名为“certs”，并为worker01创建一个配置文件：

```sh
mkdir -p /tls/worker01/certs && cd /tls/worker01/certs
echo subjectAltName = DNS:worker01,IP:10.206.16.12 > /tls/worker01/certs/extfile.cnf
```

## 3. 签名证书
在master节点上使用CA签名证书并生成tls证书：
```sh
cd /tls/worker01
openssl x509 -req -days 365 -in server.csr -CA ../ca.pem -CAkey ../ca-key.pem \
    -CAcreateserial -out server-cert.pem -extfile certs/extfile.cnf
```

## 4. 创建秘钥

在worker01节点上创建Docker使用的密钥：

```sh
sudo mkdir -p /etc/docker/certs.d
sudo openssl genrsa -out /etc/docker/certs.d/worker01:443.key 4096
```

在worker01节点上使用CA证书生成自签名证书：

需要先把master上生成的ca.pem，ca-key.pem，extfile.cnf三个文件复制到worker01:/tls

```sh
sudo openssl req -subj '/CN=worker01' -new -key /etc/docker/certs.d/worker01:443.key \
    -out /etc/docker/certs.d/worker01:443.csr
sudo openssl x509 -req -days 365 -in /etc/docker/certs.d/worker01:443.csr \
    -CA /tls/ca.pem -CAkey /tls/ca-key.pem -CAcreateserial \
	-out /etc/docker/certs.d/worker01:443.crt \
	-extfile /tls/extfile.cnf
```

## 5. 分发证书和密钥
在master节点上分发worker01节点的tls证书和私钥到相应的文件夹：
```sh
scp ca.pem worker01/server-key.pem worker01/server-cert.pem ubuntu@worker01:/tls
```

在worker节点上
```sh
mkdir -p /etc/docker/certs.d/worker01:443/
cp -f /tls/ca.pem /etc/docker/certs.d/worker01:443/ca.crt
cp -f /tls/server-key.pem /etc/docker/certs.d/worker01:443/server.key
cp -f /tls/server-cert.pem /etc/docker/certs.d/worker01:443/server.crt
```

## 6. 修改docker配置文件

在worker01节点上修改Docker配置文件以使用tls：

```sh
sudo vi /lib/systemd/system/docker.service
```

修改启动命令：

```sh
ExecStart=/usr/bin/dockerd \
--tls=true \
--tlsverify=true \
--tlscacert=/etc/docker/certs.d/worker01:443/ca.crt \
--tlscert=/etc/docker/certs.d/worker01:443/server.crt \
--tlskey=/etc/docker/certs.d/worker01:443/server.key \
-H tcp://0.0.0.0:2376 \
-H unix:///var/run/docker.sock
```

## 7. 重启Docker和Kubelet
在worker01节点上重启Docker和kubelet：

```sh
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl restart kubelet
```

## 8. 验证

现在，在master节点上使用Docker命令直接访问worker01节点上的Docker即可。例如：
```sh
docker -H tcp://worker01:2376 --tlsverify --tlscacert /tls/ca.pem --tlscert /tls/worker01/server-cert.pem --tlskey /tls/worker01/server-key.pem version
docker -H tcp://worker01:2376 --tlsverify --tlscacert /tls/ca.pem --tlscert /tls/worker01/server-cert.pem --tlskey /tls/worker01/server-key.pem images
```
