kubeadm reset -f
rm -rf /etc/cni/net.d
#apt-get install ipvsadm -y
ipvsadm --clear
rm -rf $HOME/.kube/config
