#!/bin/bash
helm repo add utkuozdemir https://utkuozdemir.org/helm-charts
helm install monitoring utkuozdemir/nvidia-gpu-exporter -n monitoring
