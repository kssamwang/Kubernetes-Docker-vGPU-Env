#/bin/bash
if [ $# -ne 1 ] ; then
	echo "wrong argument! ./delete-node.sh {worker node name}"
	exit
else
        echo "Start Deleting Node : $1"
fi

kubectl drain $1 --delete-local-data --force --ignore-daemonsets
kubectl delete nodes $1
echo "please run ./worker-reset.sh on deleted node to clear information"

