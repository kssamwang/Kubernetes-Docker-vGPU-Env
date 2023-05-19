# k8s-docker-GPU-env
## 0. 安装cuda环境

确定可用cuda版本，官网下载

[下载地址](https://developer.nvidia.com/cuda-toolkit-archive) 推荐使用runfile(local)安装

存在驱动时，不能重复安装。

以下以Ubuntu 20.04 x86——64 安装cuda 11.4版本为例：

```sh
nvidia-smi
wget https://developer.download.nvidia.com/compute/cuda/11.4.0/local_installers/cuda_11.4.0_470.42.01_linux.run
sudo sh cuda_11.4.0_470.42.01_linux.run
```
运行后勾选组件即可。

**配置环境变量，注意腾讯云GPU服务器启动时选自动安装GPU驱动，开机后过一段时间，后台自动安装完，直接到这一步配置环境变量就可以。**

path中注意替换版本号。配置后验证，出现nvcc编译器版本即为成功安装cuda工具链。

```sh
sudo echo -e "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-11.4/lib64" >> /etc/profile
sudo echo -e "export PATH=$PATH:/usr/local/cuda-11.4/bin" >> /etc/profile
source /etc/profile
nvcc -V
```
