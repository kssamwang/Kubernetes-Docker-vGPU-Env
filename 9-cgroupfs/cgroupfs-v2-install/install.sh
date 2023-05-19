#!/bin/bash
sudo apt-get install -y libcgroup1
sudo sed -i '/^#DefaultLimitCORE/c\DefaultLimitCORE=infinity' /etc/systemd/system.conf
sudo sed -i '/^#DefaultLimitNOFILE/c\DefaultLimitNOFILE=64000' /etc/systemd/system.conf
sudo systemctl daemon-reexec
cp -f ./grub /etc/default/grub
sudo update-grub
sudo reboot

