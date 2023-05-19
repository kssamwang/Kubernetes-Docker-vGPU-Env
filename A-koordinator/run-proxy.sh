#!/bin/bash
nohup koord-runtime-proxy --backend-runtime-mode=Docker --remote-runtime-service-endpoint=/var/run/docker.sock &  1>/dev/null 2>&1 &

