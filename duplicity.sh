#!/bin/bash

#set -x

ROOT="/var/www/"
DEST="/media/duplicity-backups"
RES="/media/duplicity-restore"
RES_FOLDER=$2
RES_FILE=$2
#RES_DAY="3D"   #restore backup to last 3day back

backup_webroot(){
cd $ROOT
DIR="$(ls)"
for dir in $DIR
        do
            if [[ ! -d "$DEST/$dir" ]]; then
                mkdir -p "$DEST/$dir"
                echo $ROOT$dir
                echo "$DEST/$dir"
	    fi
            case "$RES_FILE" in
                incremental)
                     nice -n 19 duplicity incremental -v 5 --no-encryption  $ROOT$dir "file://$DEST/$dir" | tee -a /var/log/duplicity-backup.log
                 ;;
                full)
                     nice -n 19 duplicity full -v 5 --no-encryption  $ROOT$dir "file://$DEST/$dir" | tee -a /var/log/duplicity-backup.log
                 ;;
                *)
                     do_nothing
		     break;
                 ;;

                # Sleep 300ms to make sure duplicity is spawned
                #sleep 0.3
                # Limit CPU usage to 10%
                # Uses http://cpulimit.sourceforge.net/
                #pid=$(pgrep duplicity)
                #[[ "$pid" -gt 0 ]] && cpulimit -b -p $pid --limit=10
                esac
        done
}

restore_webroot(){
    [[ -d "$RES/$RES_FOLDER" ]] && rm -r "$RES/$RES_FOLDER" && mkdir -p "$RES/$RES_FOLDER"
    duplicity restore --no-encryption "file://$DEST/$RES_FOLDER" "$RES/$RES_FOLDER"

}

#check if duplicity is installed
#Install Duplicity if not installed
check_duplicity_installed(){
dpkg --get-selections | grep -v deinstall | grep duplicity &> /dev/null
if [ $? -ne 0 ]; then
        echo "Duplicity not found on your system. Installing ..."
        apt-add-repository ppa:duplicity-team/ppa
        apt-get update
        apt-get install -y duplicity
        apt-get install -y python-pip
        pip install boto
        apt-get install -y python-paramiko
        apt-get install -y cpulimit
fi
}

do_nothing()
{
echo "USAGE:
  $(basename "$0") [options]
  Options:
    backup   backup root directory
    restore  restore to given path
  Commands:
     $(basename "$0") backup incremental
     $(basename "$0") backup full
     $(basename "$0") restore htdocs example.com
"
}

### MAIN ###
check_duplicity_installed

case "$1" in
"backup")
    backup_webroot
;;
"restore")
    restore_webroot
;;
*)
    do_nothing
;;
esac
