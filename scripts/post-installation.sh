#! /bin/bash

new_hostname=`cat /root/config/hostname`
hostnamectl set-hostname ${new_hostname}

python3 /usr/local/src/arch-linux-server/scripts/send-email-from-dir.py --directory=/var/mails

systemctl disable post-installation.service
rm -rf /etc/systemd/system/post-installation.service
systemctl daemon-reload
