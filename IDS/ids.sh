#!/bin/bash

#Run with: wget https://github.com/jbozzz/hackme/raw/master/IDS/ids.sh; sudo chmod +x ids.sh; sudo ./ids.sh
baseurl=https://github.com/jbozzz/hackme/raw/master/IDS
set -x #echo on
pwd=$(cat pwd)
snortreport=snortreport-1.3.4
ossecwui=ossec-wui-0.8


#Intrusion detection and log tracing

#Install Snort Network IDS
echo "create database snort;GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES ON snort.* TO 'snort'@'localhost' IDENTIFIED BY '$pwd';GRANT SELECT ON snort.* TO 'acidbase'@'localhost' IDENTIFIED BY '$pwd';FLUSH PRIVILEGES;">mysqlsnort
mysql -u root -p$pwd <mysqlsnort
echo "snort-mysql snort-mysql/address_range string 192.168.0.0/16" | sudo debconf-set-selections
echo "snort-mysql snort-mysql/db_host string localhost" | sudo debconf-set-selections
echo "snort-mysql snort-mysql/db_user string snort" | sudo debconf-set-selections
echo "snort-mysql snort-mysql/db_pass password $pwd" | sudo debconf-set-selections
echo "snort-mysql snort-mysql/db_database string snort" | sudo debconf-set-selections
echo "snort-mysql snort-mysql/configure_db boolean false" | sudo debconf-set-selections
echo "snort-mysql snort-mysql/startup select boot" | sudo debconf-set-selections
sudo apt-get -y install snort-mysql
#pushd /usr/share/doc/snort-mysql
sudo zcat /usr/share/doc/snort-mysql/create_mysql.gz | mysql -u snort -p$pwd snort
#popd
sudo sed -i "s/output\ log_tcpdump:\ tcpdump.log/#output\ log_tcpdump:\ tcpdump.log\noutput\ database:\ log,\ mysql, user=snort password=$pwd dbname=snort host=localhost/" /etc/snort/snort.conf
sudo rm -rf /etc/snort/db-pending-config
sudo touch /etc/snort/database.conf
sudo /etc/init.d/snort start
cd /usr/local/bin
#Install Pulled Pork, automated Snort rule management
sudo wget http://pulledpork.googlecode.com/svn/trunk/pulledpork.pl
sudo chmod 755 pulledpork.pl
sudo mkdir /etc/pulledpork
cd /etc/pulledpork
sudo wget http://www.rivy.org/custom/pulledpork.conf

# Custom rules
cd
wget $baseurl/hackme.rules
sudo sed -i "s/rootpassword/$pwd/g" hackme.rules
sudo mv hackme.rules /etc/snort/rules/
sudo bash -c "echo 'include $RULE_PATH/hackme.rules' >>/etc/snort/snort.conf"
sudo service snort restart

if [[ "$acidbase" = "Y" ]]; then
#Install Acidbase, front end for Snort. See http://www.question-defense.com/2012/11/08/acidbase-debconf-variables
#Removed because ACID gives the possibility to delete alerts etc.
echo acidbase acidbase/pgsql/manualconf note | sudo debconf-set-selections
echo acidbase acidbase/base_advisory note | sudo debconf-set-selections
echo acidbase acidbase/database-type select mysql | sudo debconf-set-selections
echo acidbase acidbase/mysql/admin-pass password $pwd | sudo debconf-set-selections
echo acidbase acidbase/mysql/app-pass password $pwd | sudo debconf-set-selections
echo acidbase acidbase/app-password-confirm password $pwd | sudo debconf-set-selections
echo acidbase acidbase/password-confirm password $pwd | sudo debconf-set-selections
echo acidbase acidbase/db/dbname string snort | sudo debconf-set-selections
echo libphp-adodb  libphp-adodb/pathmove note | sudo debconf-set-selections
sudo apt-get install -y acidbase
sudo sed -i "s#allow\ from\ 127.0.0.0/255.0.0.0#allow\ from\ 127.0.0.0/255.0.0.0\ 0.0.0.0/0.0.0.0#" /etc/acidbase/apache.conf
sudo sed -i "s/alert_user=''/alert_user='acidbase'/" /etc/acidbase/database.php
sudo sed -i "s/alert_password=''/alert_password='$pwd'/" /etc/acidbase/database.php
sudo sed -i "s/alert_dbname=''/alert_dbname='snort'/" /etc/acidbase/database.php
sudo sed -i "s/alert_port=''/alert_port='1521'/" /etc/acidbase/database.php
sudo sed -i "s/alert_host=''/alert_host='localhost'/" /etc/acidbase/database.php
sudo service apache2 restart
#Create acidbase tables
wget -qO- --post-data="submit=Create BASE AG" http://localhost/acidbase/base_db_setup.php|cat
cd /home/hackme
fi

#Scripts to copy logs for viewing on the web site
sudo mkdir /var/www/logs
mkdir scripts
cd scripts
rm copylogs*
wget $baseurl/copylogs.sh
chmod +x copylogs.sh
sudo sed -i "14 a* * * * * root /home/hackme/scripts/copylogs.sh" /etc/crontab 
wget $baseurl/index.html
sudo mv index.html /var/www/


#Install OSSEC Host based IDS
sudo apt-get install -y build-essential linux-headers-`uname -r`
wget http://www.ossec.net/files/ossec-hids-latest.tar.gz
tar -zxvf ossec-hids-latest.tar.gz
cd ossec-hids-*
sudo ./install.sh <<OssecInstall
en

local
/var/ossec
n
y
y
y
n
n


OssecInstall

#Install Ossec UI
cd
wget http://www.ossec.net/files/$ossecwui.tar.gz
tar -zxvf $ossecwui.tar.gz
sudo mv $ossecwui /var/www/ossec
#Replace so that password is set automatically
sudo sed -i "s#$HTPWDCMD -c \$PWD/.htpasswd \$MY_USER#$HTPWDCMD -cb \$PWD/.htpasswd \$MY_USER $pwd#" /var/www/ossec/setup.sh
cd /var/www/ossec
sudo ./setup.sh <<OssecuiInstall
ossecui
www-data
/var/ossec
OssecuiInstall

sudo usermod -a -G ossec www-data
sudo chmod 770 /var/ossec/tmp/
sudo chgrp www-data /var/ossec/tmp/
sudo apache2ctl restart



# Process accounting
# http://www.shibuvarkala.com/2009/04/howto-enable-process-accounting-in.html
sudo apt-get install -y acct
touch /var/log/pacct
sudo accton /var/log/pacct 

#Snort report
sudo apt-get install -y php5 php5-mysql php5-gd libpcap0.8-dev libpcre3-dev g++ bison flex libpcap-ruby make autoconf libtool
wget http://www.symmetrixtech.com/ids/$snortreport.tar.gz
sudo tar zxvf $snortreport.tar.gz -C /var/www/
sudo mv /var/www/$snortreport /var/www/snortreport
sudo sed -i "s/PASSWORD/$pwd/" /var/www/snortreport/srconf.php

sudo service apache2 restart
sudo service tomcat7 restart
sudo service ossec restart
