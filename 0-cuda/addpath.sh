#!/bin/bash
cudapath=$(find /usr/local -name cuda-*.* -type d)
sudo echo -e "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$cudapath/lib64" >> /etc/profile
sudo echo -e "export PATH=$PATH:$cudapath/bin" >> /etc/profile
source /etc/profile
nvcc -V
