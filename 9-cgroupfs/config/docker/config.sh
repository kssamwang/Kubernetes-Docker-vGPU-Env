#!/bin/bash
if [ $# -ne 2 ] ; then
	echo "wrong argument! ./config.sh [master/worker] [systemd/cgroupfs]"
	exit
elif [ "$1" != "master" ] && [ "$1" != "worker" ] ; then
	echo "wrong argument! ./config.sh [master/worker] [systemd/cgroupfs]"
        exit
elif [ "$2" != "systemd" ] && [ "$2" != "cgroupfs" ] ; then
	echo "wrong argument! ./config.sh [master/worker] [systemd/cgroupfs]"
        exit
else
        echo "Kubernetes   node : $1"
        echo "cgroupDriver type : $2"
fi

systemctl stop docker
cp -f "../$2/$1/daemon.json" /etc/docker/daemon.json
systemctl daemon-reload && systemctl restart docker

