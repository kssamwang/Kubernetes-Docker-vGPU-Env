#!/bin/bash
ps aux | grep koord-runtime-proxy | awk '{ print $2 }' | xargs kill -9
helm uninstall koordinator
rm -f /usr/local/bin/koord-runtime-proxy

