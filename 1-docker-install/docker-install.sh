#!/bin/bash
if [ $# -ne 1 ] ; then
	echo "wrong argument! ./docker-install.sh [master/worker]"
	exit
else
	echo "node type : $1"
fi

node=$1
mkdir -p /etc/docker

if [ $node == 'master' ] ; then
	cp -f ./master-daemon.json /etc/docker/daemon.json
elif [ $node == 'worker' ] ; then
	cp -f ./worker-daemon.json /etc/docker/daemon.json
else
	echo "wrong argument! ./docker-install.sh [master/worker]"
	exit
fi

#### Step 1: ��װ��Ҫ��һЩϵͳ����
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
#### Step 2: ��װGPG֤��
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
#### Step 3: д�����Դ��Ϣ,�����ȶ���ֿ�
sudo add-apt-repository "deb https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
#### Step 4: �鿴���԰�װ��docker�ȶ��汾��ѡ��20.10.12
sudo apt-cache madison docker-ce
sudo apt-cache madison docker-ce-cli
sudo apt-cache madison containerd.io
sudo apt-get install -y docker-ce=5:20.10.12~3-0~ubuntu-focal docker-ce-cli=5:20.10.12~3-0~ubuntu-focal containerd.io
#### Step 5��ȷ�ϰ汾������docker
docker version
### 2.2 ��װnvidia-docker2
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) 
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - 
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get clean 
sudo apt-get update
sudo apt-get install -y nvidia-docker2
sudo systemctl start docker && sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker
