#!/bin/bash
if [ $# -ne 1 ] ; then
	echo "wrong argument [systemd/cgroupfs]"
	exit
elif [ "$1" != "systemd" ] && [ "$1" != "cgroupfs" ] ; then
	echo "wrong argument [systemd/cgroupfs]"
        exit
else
	echo "cgroupDriver type : $1"
fi

systemctl stop kubelet && systemctl disable kubelet
rm -f /etc/default/kubelet
echo "KUBELET_EXTRA_ARGS=\"--cgroup-driver=$1\"" >> /etc/default/kubelet
cp -f ./10-kubeadm.conf /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
mkdir -p /var/lib/kubelet
cp -f "../$1/config.yaml" /var/lib/kubelet/config.yaml
systemctl daemon-reload
systemctl restart kubelet && systemctl enable kubelet
