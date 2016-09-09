#! /bin/bash

new_hostname=`cat /root/config/hostname`
hostnamectl set-hostname ${new_hostname}

/usr/local/bin/arch-linx-server/scripts/send-email-from-dir.py --directory=/root/mails

systemctl disable post-installation.service
rm -rf /etc/systemd/system/post-installation.service
systemctl daemon-reload
