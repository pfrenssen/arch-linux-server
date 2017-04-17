# arch-linux-server
Arch Linux Server setup scripts

This script configures an arch linux VPS installation. It is used to configure the VPS at TransIP.

First check if your DNS is configured:
```
$ ping -c 1 github.com
```

If it is not, use the TransIP DNS servers:
```
$ echo -e "nameserver 80.69.67.66\nnameserver 80.69.66.67" >> /etc/resolv.conf
```

```
wget https://github.com/pfrenssen/arch-linux-server/raw/master/setup.sh
chmod u+x setup.sh
./setup.sh
```

## Preinstalled Packages

- base
- base-devel
- certbot
- git
- openssh
- openssl
- sudo
- vim
- yaourt
- postfix *Configured for sending outgoing e-mail*
