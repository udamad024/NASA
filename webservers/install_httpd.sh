#!/bin/bash

# Update package repository and install Apache HTTP server
sudo yum -y update
sudo yum -y install httpd

# Get the instance's local IPv4 address
myip=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

# Create the index.html file with an image and three new lines with names
echo "<html><body><img src='https://mykey101.s3.amazonaws.com/new.jpg'><br/><h1><b>Group 9</b></h1><br/><b>Ashen</b><br/><b>Jun</b><br/><b>Faseh</b></body></html>" > /var/www/html/index.html

# Start and enable the Apache HTTP server
sudo systemctl start httpd
sudo systemctl enable httpd
