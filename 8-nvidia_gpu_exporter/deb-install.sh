#!/bin/bash
if [ ! -f "" ];then
	wget  https://github.com/utkuozdemir/nvidia_gpu_exporter/releases/download/v1.2.0/nvidia-gpu-exporter_1.2.0_linux_amd64.deb
fi
sudo dpkg -i nvidia-gpu-exporter_1.2.0_linux_amd64.deb
nvidia_gpu_exporter --help
cp -f ./nvidia_gpu_exporter.service /lib/systemd/system/nvidia_gpu_exporter.service
systemctl daemon-reload
systemctl start nvidia_gpu_exporter.service
systemctl enable nvidia_gpu_exporter.service
systemctl status nvidia_gpu_exporter.service

