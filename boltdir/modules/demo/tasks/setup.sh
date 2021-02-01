#!/bin/bash

# Start by erasing a package we need
yum erase unzip -y

# Break the webserver if it exists
sed -i 's/*:80>/*:8080>/' /etc/httpd/conf.d/25-$(hostname).conf

# Hack the MOTD
echo "Y0UV3 B33N HAX3D!1!!111!" >> /etc/motd

