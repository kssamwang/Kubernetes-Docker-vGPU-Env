# k8s-docker-GPU-env
搭建k8s+docker运行GPU程序的环境

## Koordinator
[Koordinator](https://koordinator.sh/zh-Hans/)是阿里云开源的k8s集群调度工具
可以动态修改pod的内存，IO，cpu等计算资源

## 安装配置Koordinator
### 1 安装Koordinator
如果能连上github：
```sh
helm repo add koordinator-sh https://koordinator-sh.github.io/charts/
helm repo update
helm install koordinator koordinator-sh/koordinator --version 1.2.0
```

如果连不上github：
```sh
helm install koordinator https://github.com/koordinator-sh/charts/releases/download/koordinator-1.2.0/koordinator-1.2.0.tgz --set imageRepositoryHost=registry.cn-beijing.aliyuncs.com
```

### 2 安装koord-runtime-proxy
注意与koordinator版本保持一致
```sh
wget https://github.com/koordinator-sh/koordinator/releases/download/v1.2.0/koord-runtime-proxy_1.2.0_linux_x86_64 -O koord-runtime-proxy
chmod +x koord-runtime-proxy
cp -f koord-runtime-proxy /usr/local/bin/
koord-runtime-proxy --help
```

### 3 配置koord-runtime-proxy
需要docker和kubelet的CGroup Driver均设置为cgroupfs，设置方法另附。
原理是代理转发cgroup driver到Docker的请求，使用Koordinator代替kubelet调度器做资源扩缩容的调度。

开启Docker socker监听：

```sh
koord-runtime-proxy --backend-runtime-mode=Docker --remote-runtime-service-endpoint=/var/run/docker.sock
```

### 4 卸载
```sh
helm uninstall koordinator
```

```
release "koordinator" uninstalled
```
