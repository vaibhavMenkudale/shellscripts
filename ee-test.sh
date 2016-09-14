#!/bin/bash

export TERM=xterm-256color
export DEBIAN_FRONTEND noninteractive
export LC_CTYPE=en_US.UTF-8
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8
bash -c 'echo -e "[user]\n\tname = abc\n\temail = root@localhost.com" > ~/.gitconfig'
rm -rf ~/.gnupg
sudo rm -rf /etc/mysql/
sudo bash -c 'echo example.com > /etc/hostname'
sudo service hostname restart
sudo apt-get -qq purge mysql* graphviz*
sudo apt-get -qq autoremove
sudo apt-get update
wget rt.cx/ee && sudo bash ee

sudo ee --help
sudo ee stack install
sudo ee stack install --web
sudo ee stack install --admin

sudo ee site create html.net --html
sudo ee site create php.com --php
sudo ee site create mysql.com --mysql
sudo ee site create site1.com --wp

sudo ee site create site2.net --wp --wpsc
sudo ee site create site3.net --wp --w3tc
sudo ee site create site4.com --wpfc
sudo ee site create site4.net --wp --wpfc
sudo ee site create site4.org --wpfc --wp
sudo ee site create site5.com --wpsubdir

sudo ee site create site6.com --wpsubdir --wpsc
sudo ee site create site7.com --wpsubdir --w3tc
sudo ee site create site8.com --wpsubdir --wpfc
sudo ee site create site8.net --wpfc --wpsubdir
sudo ee site create site9.com --wpsubdomain

sudo ee site create site10.org --wpsubdomain --wpsc
sudo ee site create site11.org --wpsubdomain --w3tc
sudo ee site create site12.org --wpsubdomain --wpfc
sudo ee site create site12.in --wpfc --wpsubdomain

sudo ee site create site.hhvm2.com --wpsc --hhvm
sudo ee site create site.hhvm4.com --wpfc --hhvm
sudo ee site create site.hhvm5.com --wpsubdir --hhvm
sudo ee site create site.hhvm6.com --wpsubdir --wpsc --hhvm
sudo ee site create site.hhvm8.com --wpsubdir --wpfc --hhvm
sudo ee site create site.hhvm9.com --wpsubdomain --hhvm
sudo ee site create site.hhvm10.org --wpsubdomain --wpsc --hhvm
sudo ee site create site.hhvm12.in --wpfc --wpsubdomain --hhvm

sudo ee site create site1.localtest.me --php --mysql
sudo ee site create site2.localtest.me --mysql --html
sudo ee site create site3.localtest.me --php --html
sudo ee site create site4.localtest.me --wp --wpsubdomain
sudo ee site create site5.localtest.me --wp --wpsubdir --wpfc
sudo ee site create site6.localtest.me --wpredis
sudo ee site create site7.localtest.me --wpsubdomain --wpredis
sudo ee site create site8.localtest.me --wpsubdir --wpredis

sudo ee debug --all
sudo ee debug --all=off
sudo ee debug site12.net
sudo ee debug site12.net --all=off
sudo ee site create 1.com --html
sudo ee site create 2.com --php
sudo ee site create 3.com --mysql

sudo ee site update 1.com --wp
sudo ee site update 2.com --wpsubdir
sudo ee site update 3.com --wpsubdomain

sudo ee site update site1.com --wp --wpfc
sudo ee site update site1.com --wp --w3tc
sudo ee site update site1.com --wp --wpsc
sudo ee site update site1.com --wpredis

sudo ee site update site5.com --wpsubdir --wpfc
sudo ee site update site5.com --wpsubdir --wpsc

sudo ee site update site9.com --wpsubdomain --wpfc
sudo ee site update site9.com --wpsubdomain --wpsc
sudo ee site update site.hhvm12.in --hhvm=off
sudo ee site update site9.com --hhvm
sudo ee site info site.hhvm12.in
sudo ee site info site9.com

sudo ee site create www.site-1.com --wp
sudo ee site create www.subsite.site-1.com --wpfc
sudo ee site update www.subsite.site-1.com --wp
sudo ee site delete www.subsite.site-1.com --all --no-prompt

sudo ee site delete site12.in --all --no-prompt

sudo ee stack install --mail
sudo ls /var/www/
sudo wp --allow-root --info
sudo bash -c 'cat /var/log/ee/ee.log'