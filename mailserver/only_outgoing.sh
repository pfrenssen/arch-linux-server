#! /bin/bash -x

admin_username=`cat /root/config/admin_username`

cd /usr/local/src/arch-linux-server

sudo pacman --noconfirm -S postfix

sudo echo "
# Simple spam prevention. Taken from http://www.netarky.com/programming/arch_linux/Arch_Linux_mail_server_setup_1.html
smtpd_helo_required = yes
smtpd_helo_restrictions = reject_non_fqdn_helo_hostname, reject_unknown_helo_hostname
smtpd_delay_reject = yes
inet_interfaces = loopback-only
" >> /etc/postfix/main.cf

sudo echo "
# Person who should get root's mail. Don't receive mail as root!
spam:   root
ham:    root
root:   $admin_username
" >> /etc/postfix/aliases

newaliases

sudo systemctl enable postfix
