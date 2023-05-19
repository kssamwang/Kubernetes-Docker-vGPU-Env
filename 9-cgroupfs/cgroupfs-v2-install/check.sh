#!/bin/bash
if [ -f "/sys/fs/cgroup/cgroup.controllers" ];then
	echo "cgroupfs v2 is enabled."
else
	echo "cgroupfs v2 is unenabled."
fi

check2=$(cat /sys/kernel/mm/transparent_hugepage/enabled)
if [ "$check2" == "always [madvise] never" ] || [ "$check2" == "[always] madvise never" ];then
	echo "hugetlb cgroups is enabled."
else
	echo "cgroupfs v2 is unenabled."
fi
