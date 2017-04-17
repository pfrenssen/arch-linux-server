#! /bin/bash
# This script has to be executed after a chroot

cd /usr/local/src
rm -rf arch-linux-server
git clone https://github.com/pfrenssen/arch-linux-server.git

new_hostname=`cat /root/config/hostname`
admin_username=`cat /root/config/admin_username`
admin_user_email=`cat /root/config/admin_user_email`

rm /etc/localtime
ln -s /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
hwclock --systohc --utc

sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

systemctl enable dhcpcd@ens3.service
systemctl start dhcpcd@ens3.service

touch /etc/iptables/iptables.rules
systemctl enable iptables
systemctl start iptables

# Update mirrorlist and rank by fastest mirrors.
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
for country in BE DE DK GB NL; do
  curl -s "https://www.archlinux.org/mirrorlist/?country=$country&use_mirror_status=on" >> /etc/pacman.d/mirrorlist
done;
sed -i 's/^#Server/Server/g' /etc/pacman.d/mirrorlist
sed -i '/^#/d' /etc/pacman.d/mirrorlist
rankmirrors /etc/pacman.d/mirrorlist > /etc/pacman.d/mirrorlist

# Install basic packages needed to complete installation.
pacman --noconfirm -Sy vim grub sudo openssh openssl certbot python3

mkinitcpio -p linux

grub-install --target=i386-pc /dev/vda
grub-mkconfig -o /boot/grub/grub.cfg

echo "%wheel      ALL=(ALL) ALL" >> /etc/sudoers
systemctl enable sshd
systemctl start sshd

# Install outgoing mailserver
arch-linux-server/mailserver/only_outgoing.sh

# Create a default certificate
certbot certonly --non-interactive --standalone -d $new_hostname --email $admin_user_email --agree-tos
ln -s /etc/letsencrypt/live/$new_hostname /etc/letsencrypt/root
cp arch-linux-server/config/etc/systemd/system/certbot.timer /etc/systemd/system/certbot.timer
cp arch-linux-server/config/etc/systemd/system/certbot.service /etc/systemd/system/certbot.service
systemctl daemon-reload
systemctl enable certbot.timer
systemctl start certbot.timer

# Add users
useradd -m -G wheel ${admin_username}
mkdir -p /home/${admin_username}/.ssh
if [ -f "arch-linux-server/public_keys/${admin_username}/id_rsa.pub" ]
then
  cp arch-linux-server/public_keys/$admin_username/id_rsa.pub /home/$admin_username/.ssh/authorized_keys
fi
chown -R $admin_username.$admin_username /home/${admin_username}/.ssh

random_passwd_root=$(curl -s "https://makemeapassword.org/api/v1/passphrase/plain?pc=1&wc=4&sp=y&maxCh=64&whenUp=StartOfWord&whenNum=StartOrEndOfWord")
random_passwd_user=$(curl -s "https://makemeapassword.org/api/v1/passphrase/plain?pc=1&wc=4&sp=y&maxCh=64&whenUp=StartOfWord&whenNum=StartOrEndOfWord")
echo -e "root:$random_passwd_root" | chpasswd
echo -e "$admin_username:$random_passwd_user" | chpasswd

mkdir /var/www
chmod a+x /var/www
ln -s /var/www /home/$admin_username/www
mkdir /var/mails
chmod 777 /var/mails
echo "root@$new_hostname
$admin_user_email
New server ready
Your server is ready below are your login details.

Login with ssh at $new_hostname
User: $admin_username
Password: $random_passwd_user

Root passwd: $random_passwd_root

" > /var/mails/newserver.email

echo ${admin_username} >> /root/.forward
echo ${admin_user_email} >> /home/$admin_username/.forward
chown $admin_username.$admin_username /home/$admin_username/.forward

cp arch-linux-server/config/etc/systemd/system/post-installation.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable post-installation.service

cat /var/mails/newserver.email
