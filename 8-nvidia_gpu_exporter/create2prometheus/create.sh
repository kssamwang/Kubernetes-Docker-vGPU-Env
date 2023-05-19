#!/bin/bash
echo "please confirm that:"
echo "  1. Node IP of every node in the cluster has been added into gpu-exporter-endpoint.yaml."
echo "  2. status of system service nvidia_gpu_export.service is running(active)."
echo "  3. Pods of kube-prometheus are normly running in namespace monitoring."
read -p "comfirm [yes/no] : " cmd
if [ "$cmd" == "yes" ] || [ "$cmd" == "Yes" ];then
	kubectl apply -f gpu-exporter-endpoint.yaml
	kubectl apply -f gpu-exporter-service.yaml
	kubectl apply -f gpu-exporter-serviceMonitor.yaml
else
	echo "Abort."
fi


