#!/bin/bash
if [ ! -f "koord-runtime-proxy_1.2.0_linux_x86_64" ];then
	wget https://github.com/koordinator-sh/koordinator/releases/download/v1.2.0/koord-runtime-proxy_1.2.0_linux_x86_64
	chmod +x koord-runtime-proxy
fi
cp -f koord-runtime-proxy_1.2.0_linux_x86_64 /usr/local/bin/koord-runtime-proxy
koord-runtime-proxy --help

