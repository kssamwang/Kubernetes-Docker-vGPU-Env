#!/bin/bash
cnt=$(echo $PATH | grep "/usr/local/go/bin" | wc -l)
if [ $cnt -eq 0 ];then
	echo -e "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile
fi
source /etc/profile
go version
