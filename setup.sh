#! /usr/bin/sh

mkdir config

# Set Hostname
echo "What is the hostname?"
read new_hostname
echo ${new_hostname} >> config/hostname

echo "What should be your username?"
read admin_username
echo ${admin_username} >> config/admin_username

echo "What is your e-mail address?"
read admin_user_email
echo ${admin_user_email} >> config/admin_user_email

# Disable zram if it is enabled, so it doesn't end up in /etc/fstab.
zram_enabled=`fdisk -l | grep '/dev/zram0'`
if [[ -n $zram_enabled ]]; then
  swapoff /dev/zram0
  rmmod zram
fi

parted /dev/vda -s mklabel msdos
parted /dev/vda -s mkpart primary ext4 1MiB 90%
parted /dev/vda -s set 1 boot on
parted /dev/vda -s mkpart primary ext4 90% 95%
parted /dev/vda -s mkpart primary linux-swap 95% 100%

mkfs.ext4 /dev/vda1
mkfs.ext4 /dev/vda2
mkswap /dev/vda3
swapon /dev/vda3

mount /dev/vda1 /mnt
mkdir /mnt/tmp
mount /dev/vda2 /mnt/tmp

pacstrap /mnt base base-devel git

genfstab -p /mnt >> /mnt/etc/fstab

wget https://github.com/pfrenssen/arch-linux-server/raw/master/setup-chrooted.sh -O /mnt/root/setup-chrooted.sh
chmod u+x /mnt/root/setup-chrooted.sh
cp -R config /mnt/root/config
arch-chroot /mnt /root/setup-chrooted.sh

read -p "Press enter to reboot"
reboot
