#!/bin/bash
sudo yum -y update
sudo yum -y install httpd
myip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
echo "<html><body><img src='https://mykey101.s3.amazonaws.com/new.jpg'></body></html>" > /var/www/html/index.html
sudo systemctl start httpd
sudo systemctl enable httpd