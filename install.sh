#!/bin/bash

## Change user password
## --------------------
passwd ${USER}

## Configure APT sources
## ---------------------
sudo add-apt-repository -y main && sudo add-apt-repository -y restricted && sudo add-apt-repository -y universe && sudo add-apt-repository -y multiverse

## Keep system safe
## ----------------
sudo apt-get -y update && sudo apt-get -y upgrade && sudo apt-get -y dist-upgrade
sudo apt-get -y remove && sudo apt-get -y autoremove
sudo apt-get -y clean && sudo apt-get -y autoclean

## Disable error reporting
## -----------------------
sudo sed -i "s/enabled=1/enabled=0/" /etc/default/apport

## Edit SSH settings
## -----------------
sudo sed -i "s/#Port 22/Port 49622/" /etc/ssh/sshd_config
sudo sed -i "s/#LoginGraceTime 2m/LoginGraceTime 2m/" /etc/ssh/sshd_config
sudo sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin no/" /etc/ssh/sshd_config
sudo sed -i "s/#StrictModes yes/StrictModes yes/" /etc/ssh/sshd_config
sudo systemctl restart sshd.service

## Install prerequisite packages
## -----------------------------
sudo apt-get -y install libsodium-dev

## Install necessary softwares
sudo apt-get -y install apache2 apt-transport-https autoconf curl build-essential fail2ban gcc git gpg make nano software-properties-common unattended-upgrades tor torsocks wget
sudo systemctl status apache2.service
sudo systemctl enable tor.service

## Install PHP 8.3
## ---------------
sudo add-apt-repository -y ppa:ondrej/php
sudo apt-get -y update
sudo apt-get -y install php8.3 php8.3-cli php8.3-{bz2,curl,mbstring,intl} libapache2-mod-php8.3 
sudo a2enmod php8.3
sudo systemctl reload apache2.service
sudo truncate -s 0 /var/www/html/index.html

## Edit Fail2Ban settings
## ----------------------
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl restart fail2ban.service 
sudo systemctl status fail2ban.service 

## Setting the firewall
## --------------------
sudo ufw app list
sudo ufw allow OpenSSH
sudo ufw allow 49622/tcp
sudo ufw allow 80/tcp
sudo ufw enable
sudo ufw status