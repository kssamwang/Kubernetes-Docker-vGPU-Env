# Kubernetes-Docker-vGPU-Env
搭建k8s+docker运行GPU程序的环境

## 3 安装helm
在github上helm的[版本日志](https://github.com/helm/helm/releases)有各个版本的下载

helm版本与k8s有很强对应关系，选择3.10.3适配k8s v1.23.6

可以从[华为云镜像](https://mirrors.huaweicloud.com/helm)下载

解压后，将helm复制到/usr/local/bin目录中，chmod +x
