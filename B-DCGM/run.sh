#!/bin/bash
helm install --generate-name gpu-helm-charts/dcgm-exporter -n monitoring
POD_NAME=$(kubectl get pods -n monitoring | grep dcgm-exporter | awk ' { print $1 } ')
#echo $POD_NAME
RELEASE_NAME=${POD_NAME:0:24}
#echo $RELEASE_NAME
nohup kubectl -n monitoring port-forward $POD_NAME 8080:9400  1>/dev/null 2>&1 &

echo "Notes:"
echo "RUN this to uninstall:"
echo "helm uninstall $RELEASE_NAME --namespace monitoring"

