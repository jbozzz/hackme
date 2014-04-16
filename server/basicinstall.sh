#!/bin/bash

#Run with: wget https://github.com/jbozzz/hackme/raw/master/server/basicinstall.sh; sudo chmod +x basicinstall.sh; sudo ./basicinstall.sh

set -x #echo on
baseurl=https://github.com/jbozzz/hackme/raw/master/server
cd

# Update O.S.
sudo apt-get update -y --force-yes
sudo apt-get upgrade -y --force-yes

#Install unatended upgrades
sudo apt-get install unattended-upgrades -y

#Create random difficult password
< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32} >pwd
# echo secret>pwd
pwd=$(cat pwd)
# to do: upload password to server


#Install ssh
sudo apt-get install openssh-server -y
sudo apt-get install libcrypt-ssleay-perl liblwp-protocol-https-perl -y
#Install Java
sudo apt-get install openjdk-7-jre -y
#Install Tomcat7
sudo apt-get install tomcat7-admin -y
sudo apt-get install tomcat7 -y
#Install Apache
sudo apt-get install apache2 -y
sudo a2enmod proxy_ajp
#Install MySQL
echo "mysql-server mysql-server/root_password password $pwd" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $pwd" | sudo debconf-set-selections
sudo apt-get -q -y install mysql-server


#Configure AJP between Apache and Tomcat
wget $baseurl/server.xml
sudo mv server.xml /var/lib/tomcat7/conf/
sudo sed -i '/ProxyPass/d' /etc/apache2/sites-enabled/000-default
sudo sed -i '2i     ProxyPass /tomcat/ ajp://localhost:8009/' /etc/apache2/sites-enabled/000-default
sudo sed -i '2i     ProxyPassReverse /tomcat/ [***]ajp://localhost:8009/' /etc/apache2/sites-enabled/000-default

#Deploy our web application
cd
wget $baseurl/hackme.war
sudo rm -r /var/lib/tomcat7/webapps/ROOT
sudo mv hackme.war /var/lib/tomcat7/webapps/ROOT.war 

#Install IDS
cd
wget $baseurl/../IDS/ids.sh
chmod +x ids.sh
sudo ./ids.sh
