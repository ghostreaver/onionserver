## Onion Server

Setup for a server hosting Tor Hidden services (Websites) on Ubuntu 22.04 server freshly installed.

* * *

#### Change the user password

Change user password

```shell
passwd ${USER}
```

* * *

#### Prepare the environment

Configure APT sources

```shell
sudo add-apt-repository -y main && sudo add-apt-repository -y restricted && sudo add-apt-repository -y universe && sudo add-apt-repository -y multiverse
```

Keep system safe

```shell
sudo apt-get -y update && sudo apt-get -y upgrade && sudo apt-get -y dist-upgrade
sudo apt-get -y remove && sudo apt-get -y autoremove
sudo apt-get -y clean && sudo apt-get -y autoclean
```

Disable error reporting

```shell
sudo sed -i "s/enabled=1/enabled=0/" /etc/default/apport
```

Edit SSH settings

```shell
sudo sed -i "s/#Port 22/Port 49622/" /etc/ssh/sshd_config
sudo sed -i "s/#LoginGraceTime 2m/LoginGraceTime 2m/" /etc/ssh/sshd_config
sudo sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin no/" /etc/ssh/sshd_config
sudo sed -i "s/#StrictModes yes/StrictModes yes/" /etc/ssh/sshd_config
sudo systemctl restart sshd.service
```

Install prerequisite packages

```shell
sudo apt-get -y install libsodium-dev
```

Install necessary softwares

```shell
sudo apt-get -y install apache2 apt-transport-https autoconf curl build-essential fail2ban gcc git gpg make nano software-properties-common unattended-upgrades tor torsocks wget
sudo systemctl status apache2.service
sudo systemctl enable tor.service
```

Install PHP 8.3

```shell
sudo add-apt-repository -y ppa:ondrej/php
sudo apt-get -y update
sudo apt-get -y install php8.3 php8.3-cli php8.3-{bz2,curl,mbstring,intl} libapache2-mod-php8.3 
sudo a2enmod php8.3
sudo systemctl reload apache2.service
sudo truncate -s 0 /var/www/html/index.html
```

Edit Fail2Ban settings

```shell
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl restart fail2ban.service 
sudo systemctl status fail2ban.service 
```

Setting the firewall

```shell
sudo ufw app list
sudo ufw allow OpenSSH
sudo ufw allow 49622/tcp
sudo ufw allow 80/tcp
sudo ufw enable
sudo ufw status
```

Reboot server

```shell
sudo reboot now
```

* * *

#### Automated Setup

If you prefer and in order to save time, you can use our deployment script which reproduces all the commands above.

```shell
cd /tmp/ && wget -O - https://raw.githubusercontent.com/ghostreaver/onionserver/main/install.sh | bash
```

* * *

#### Create Onion Address

There are several ways to create a `.onion` address. We will see here two ways of proceeding. The first is to use the built-in Tor feature and the second is to use `mkp224o` script allowing you to customize the onion address you want to use.

**Create `.onion` address using Tor Built-in feature**

```shell
sudo nano /etc/tor/torrc
HiddenServiceDir /var/lib/tor/<service-name>/
HiddenServicePort 80 127.0.0.1:80
sudo systemctl reload tor.service
sudo systemctl restart tor.service
sudo systemctl status tor.service
```

Retrieve the Hidden Service URL

```shell
sudo -s
cat /var/lib/tor/service-name/hostname
exit
```

**Create `.onion` domain name using a `mkp224o` script**

To configure a vanity onion address, you need to generate a new private key to match a custom hostname. To get started, clone the `mkp224o` repository onto your system, generate the required Autotools infrastructure, configure, and compile:

```shell
cd /tmp/
git clone https://github.com/cathugger/mkp224o
cd mkp224o/
./autogen.sh
./configure
make
```

Using mkp224o

```shell
./mkp224o -h
Usage: ./mkp224o FILTER [FILTER...] [OPTION]
       ./mkp224o -f FILTERFILE [OPTION]
Options:
  -f FILTERFILE         specify filter file which contains filters separated
                        by newlines.
  -D                    deduplicate filters.
  -q                    do not print diagnostic output to stderr.
  -x                    do not print onion names.
  -v                    print more diagnostic data.
  -o FILENAME           output onion names to specified file (append).
  -O FILENAME           output onion names to specified file (overwrite).
  -F                    include directory names in onion names output.
  -d DIRNAME            output directory.
  -t NUMTHREADS         specify number of threads to utilise
                        (default - try detecting CPU core count).
  -j NUMTHREADS         same as -t.
  -n NUMKEYS            specify number of keys (default - 0 - unlimited).
  -N NUMWORDS           specify number of words per key (default - 1).
  -Z                    deprecated, does nothing.
  -z                    deprecated, does nothing.
  -B                    use batching key generation method (current default).
  -s                    print statistics each 10 seconds.
  -S SECONDS            print statistics every specified amount of seconds.
  -T                    do not reset statistics counters when printing.
  -y                    output generated keys in YAML format instead of
                        dumping them to filesystem.
  -Y [FILENAME [host.onion]]
                        parse YAML encoded input and extract key(s) to
                        filesystem.
  -p PASSPHRASE         use passphrase to initialize the random seed with.
  -P                    same as -p, but takes passphrase from PASSPHRASE
                        environment variable.
  --checkpoint filename
                        load/save checkpoint of progress to specified file
                        (requires passphrase).
  --skipnear            skip near passphrase keys; you probably want this
                        because of improved safety unless you\'re trying to
                        regenerate an old key; possible future default.
  --warnnear            print warning about passphrase key being near another
                        (safety hazard); prefer --skipnear to this unless
                        you\'re regenerating an old key.
      --rawyaml         raw (unprefixed) public/secret keys for -y/-Y
                        (may be useful for tor controller API).
  -h, --help, --usage   print help to stdout and quit.
  -V, --version         print version information to stdout and exit.

```

Following the above help output, in the below example, "fast" is the prefix to use in our generated onion address. The "t" flag represent the number of simultaneous threads to execute. The "v" flag is used to print more diagnostic, the "n" flag is the number of onion addresses to generate and finally the "d" flag is the path of the output where the generated onion addresses will be temporary saved.

```shell
./mkp224o fast -t 4 -v -n 4 -d /path/to/output/
```

Copy key folder to where you want your service keys to reside:

```shell
sudo -s
cp -r neko54as6d54....onion /var/lib/tor/<service-name>
chown -R debian-tor:debian-tor /var/lib/tor/<service-name>
chmod -R u+rwX,og-rwx /var/lib/tor/<service-name>
```

Then edit `/etc/tor/torrc` and add new service with that folder.

```shell
sudo systemctl reload tor.service
sudo systemctl restart tor.service
sudo systemctl status tor.service
```

* * *

#### Create Virtual Host

We will now create a virtual host which will host the content of our site.

```shell
sudo mkdir -p /var/www/<onion-url>/public_html
sudo chown -R $USER:$USER /var/www/<onion-url>/public_html
sudo chmod -R 755 /var/www
echo "Hello Domain" | sudo tee /var/www/<onion-url>/public_html/index.html >/dev/null
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/<onion-url>.conf
sudo nano /etc/apache2/sites-available/<onion-url>.conf
```

Copy and edit the below content according to your hidden service URL.

```
<VirtualHost *:80>
    ServerAdmin webmaster@<onion-url>
    ServerName <onion-url>
    ServerAlias www.<onion-url>
    DocumentRoot /var/www/<onion-url>/public_html 
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost> 
```

Add the website to Apache configuration

```shell
sudo a2ensite <onion-url>.conf
```

Check the configuration

```shell
sudo apache2ctl configtest
```

Restart Apache server

```shell
sudo systemctl restart apache2.service
```

* * *

#### Automated Setup

If you prefer you can uses our automated script to deploy your server using the following command.

```shell
cd /tmp/ && wget -O - https://raw.githubusercontent.com/ghostreaver/onionserver/main/install.sh | bash
```

* * *

#### Conclusion


We can now visit our website using **Tor Browser** and pointing to the onion address we just configured above.