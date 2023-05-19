#!/bin/bash
helm repo add koordinator-sh https://koordinator-sh.github.io/charts/
helm repo update
docker pull registry.cn-beijing.aliyuncs.com/koordinator-sh/koordlet:v1.2.0
docker pull registry.cn-beijing.aliyuncs.com/koordinator-sh/koord-scheduler:v1.2.0
docker pull registry.cn-beijing.aliyuncs.com/koordinator-sh/koord-descheduler:v1.2.0
docker pull registry.cn-beijing.aliyuncs.com/koordinator-sh/koord-manager:v1.2.0
