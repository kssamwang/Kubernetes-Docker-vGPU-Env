# k8s-docker-GPU-env
搭建k8s+docker运行GPU程序的环境

## 4 Go语言环境搭建
以安装1.20为例（和k8s使用的go版本一致），解压后设置环境变量即可。

```sh
wget https://dl.google.com/go/go1.20.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.20.linux-amd64.tar.gz
sudo echo -e "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile
source /etc/profile
go version
```
