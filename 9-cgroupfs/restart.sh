#!/bin/bash
systemctl enable docker
systemctl enable kubelet
systemctl daemon-reload && systemctl restart docker
systemctl daemon-reload && systemctl restart kubelet
systemctl status docker
systemctl status kubelet
cat /sys/fs/cgroup/cgroup.controllers
