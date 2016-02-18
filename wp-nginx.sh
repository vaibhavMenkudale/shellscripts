#!/bin/bash
nginx_home="/var/www/html/"
wp_latest="http://wordpress.org/latest.zip"
wp_opt="/tmp/wordepress_latest.zip"
wp="${nginx_home}wordpress/"
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
echo "$msg"
echo
exit 1
fi
}
install(){
        if hash $1 2> /dev/null; then
                echo
                echo "$1 Installed. Continuing..."
                echo
                sleep 2
        else
                echo
                echo "$1 not found. Installing..."
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
install mysql mysql-server
sudo mysql_install_db
[[ ! -e /usr/share/php5/mysql/mysql.ini ]] && echo "php5-mysql Installed. Continuing..." || install php5-mysql php5-mysql
install php5-fpm php5-fpm

cp /etc/php5/fpm/php.ini /tmp/php.tmp
sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /tmp/php.tmp
sudo mv /tmp/php.tmp /etc/php5/fpm/php.ini
echo "Restarting php5-fpm service"
sudo service php5-fpm restart

echo
echo "Please enter your domain name: "
echo
read dName

sudo bash -c 'echo "127.0.0.1 '${dName}'" >> /etc/hosts && exit'
exitfn

cp /etc/nginx/sites-available/default /tmp/default.tmp
sed -i -e "s/server_name _;/server_name $dName;/" /tmp/default.tmp
sed -i -e "s/index.html/index.html index.php/" /tmp/default.tmp
sed -i -e "s#/var/www/html;#/var/www/html/wordpress;#" /tmp/default.tmp
echo "$(ed -s /tmp/default.tmp << eof
66i
${php}
.
wq
eof
)"
sudo mv /tmp/default.tmp /etc/nginx/sites-available/default

if hash wget 2> /dev/null; then
        echo
        echo "wget Installed. Continuing..."
        echo
        wget -c $wp_latest -O $wp_opt
	exitfn
else
        echo
        echo "wget not found. Installing..."
        echo
        sudo apt-get install wget
        wget $wp_latest -O $wp_opt
	exitfn
fi


if hash unzip 2> /dev/null; then
        echo
        echo "unzip Installed. Continuing..."
        echo
        sudo unzip -a $wp_opt -d $nginx_home
	exitfn
else
        echo
        echo "unzip not found. Installing..."
        echo
        sudo apt-get install unzip
        sudo unzip -a $wp_opt -d $nginx_home
	exitfn
fi

db="${dName}_db"
cmd="create database $db"
mysql -uroot -h localhost -e "${cmd}"
exitfn
echo "$(sudo sed -i -e s/database_name_here/$db/g $wp"wp-config-sample.php")"
echo "$(sudo sed -i -e s/username_here/root/g $wp"wp-config-sample.php")"
echo "$(sudo sed -i -e s/password_here//g $wp"wp-config-sample.php")"
sudo mv $wp"wp-config-sample.php" $wp"wp-config.php"
###
sudo chown -R www-data:www-data /var/www/html/
###
rm -f $wp_opt
echo "Restarting webserver"
sleep 1
service nginx restart
if (( $? )); then
echo
echo "$msg"
echo
exit 1
else
echo "Everything done. You can now test the running site on a web browser by going to 127.0.0.1"
exit 0
fi
