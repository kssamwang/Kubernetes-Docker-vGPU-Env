#!/bin/bash
POD_NAME=$(kubectl get pods -n monitoring | grep dcgm-exporter | awk ' { print $1 } ')
RELEASE_NAME=${POD_NAME:0:24}
helm uninstall $RELEASE_NAME --namespace monitoring

