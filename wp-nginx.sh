#!/bin/bash
nginx_home="/usr/share/nginx/html"
wp_latest="http://wordpress.org/latest.zip"
wp_opt="/tmp/wordepress_latest.zip"
wp="${nginx_home}/wordpress"
msg="Last command exited with non 0 status. Exiting."
date="$(stat -c %y /var/lib/apt/periodic/update-success-stamp | cut -d' ' -f1)"
lastD="$(date -d $date +'%Y%m%d')"
currentD="$(date +'%Y%m%d')"
php='error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }'
exitfn(){
if (( $? )); then
echo
echo -e "\e[31m$msg";tput sgr0;
echo
exit 1
fi
}
install(){
        if hash $1 2> /dev/null; then
                echo
                echo -e '\e[32m'"$1 Installed. Continuing...";tput sgr0;
                echo
                sleep 2
        else
                echo
                echo -e '\e[31m'"$1 not found. Installing...";tput sgr0;
                echo
                sleep 2
                sudo apt-get install $2 -y
		exitfn
        fi

}

if [[ $lastD -ne $currentD ]]; then
	sudo apt-get update
fi
install nginx nginx
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password rootpassword'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password rootpassword'
install mysql mysql-server
[[ -e /usr/share/php5/mysql/mysql.ini ]] && echo -e "\e[32mphp5-mysql Installed. Continuing..." || install php5-mysql php5-mysql
tput sgr0
install php5-fpm php5-fpm

cp /etc/php5/fpm/php.ini /tmp/php.tmp
sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /tmp/php.tmp
sudo mv /tmp/php.tmp /etc/php5/fpm/php.ini
echo
echo -e "\e[34mRestarting php5-fpm service";tput sgr0;
echo
sudo service php5-fpm restart
sleep 2

echo
echo -e "Please enter your domain name.";tput sgr0;
echo -n ": "
read dName
hName=$dName
dName=`echo $dName|tr [:punct:] _`

if grep --quiet -e "127.0.0.1 '${hName}'" /etc/hosts; then
	echo
	echo -e "\e[32mHost entry already done.";tput sgr0;
	echo
	sleep 2
else
	sudo bash -c 'echo "127.0.0.1 '${hName}'" >> /etc/hosts && exit'
	exitfn
fi

cp /etc/nginx/sites-available/default /tmp/default.tmp
sed -i -e "0,/.*server_name.*/s/.*server_name.*/        server_name $hName;/" /tmp/default.tmp
if grep --quiet -e 'index.html index.php' /etc/nginx/sites-available/default; then
	echo > /dev/null
else
	sed -i -e "s/index.html/index.html index.php/" /tmp/default.tmp
fi
sed -i -e "s#$nginx_home;#$wp;#" /tmp/default.tmp

if grep --quiet -e 'try_files $uri =404;' /etc/nginx/sites-available/default; then
	echo
	echo -e "\e[32mnginx already configured. Continuing...";tput sgr0;
	echo
	sleep 2
else
echo "$(ed -s /tmp/default.tmp << eof
66i
${php}
.
wq
eof
)"
fi
sudo mv /tmp/default.tmp /etc/nginx/sites-available/default

if hash wget 2> /dev/null; then
        echo
        echo -e "\e[32mwget Installed. Continuing...";tput sgr0;
        echo
	sleep 1
        wget -c $wp_latest -O $wp_opt
	exitfn
else
        echo
        echo -e "\e[31mwget not found. Installing...";tput sgr0;
        echo
        sudo apt-get install wget
        wget $wp_latest -O $wp_opt
	exitfn
fi


if hash unzip 2> /dev/null; then
        echo
        echo -e "\e[32munzip Installed. Continuing...";tput sgr0;
        echo
	sleep 1
        sudo unzip -a $wp_opt -d $nginx_home"/"
	exitfn
else
        echo
        echo -e "\e[31munzip not found. Installing...";tput sgr0;
        echo
        sudo apt-get install unzip
        sudo unzip -a $wp_opt -d $nginx_home"/"
	exitfn
fi

db="${dName}_db"
cmd="create database $db"
[[ -e /var/lib/mysql/$db ]] && echo -e '\e[32m'"MySQL Database already created. Continuing..." || mysql -uroot -prootpassword -h localhost -e "${cmd}"
tput sgr0
exitfn
echo "$(sudo sed -i -e s/database_name_here/$db/g $wp"/wp-config-sample.php")"
echo "$(sudo sed -i -e s/username_here/root/g $wp"/wp-config-sample.php")"
echo "$(sudo sed -i -e s/password_here/rootpassword/g $wp"/wp-config-sample.php")"
sudo mv $wp"/wp-config-sample.php" $wp"/wp-config.php"
echo
echo -e "\e[31mPhp is interfacing with MySQL by root account and default root password is set. Consider using another account and setting another stronger password for it."
echo -e "You will need to change the password at line 121(vi +121 wp-nginx.sh) for USER and line 122(vi +122 wp-nginx.sh) for PASSWORD.";tput sgr0;
sleep 3
###
sudo chown -R www-data:www-data ${nginx_home}"/" 
###
rm -f $wp_opt
echo -e "\e[34mRestarting webserver";tput sgr0;
sleep 1
sudo service nginx restart
exitfn
if (( $? )); then
	echo
	echo -e "\e[31m$msg";tput sgr0;
	echo
	exit 1
else
	echo -e "\e[32mEverything done. You can now test the running site on a web browser by going to 127.0.0.1";tput sgr0;
	exit 0
fi
