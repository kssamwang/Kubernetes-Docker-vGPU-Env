#!/bin/bash
cnt=$(cat ~/.bash_profile | grep "export KUBECONFIG=/etc/kubernetes/admin.conf" | wc -l)
if [ $cnt -eq 0 ];then
	echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile	
fi
source ~/.bash_profile

