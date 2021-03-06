#!/bin/bash

exclude=""
include=""
expath=""
inpath=""
restDay=""
ROOT="/var/www/"
DEST="/media/duplicity-backups"
RES="/media/duplicity-restore"

backup_webroot(){

if [[ -z "$vlevel" ]]; then vlevel=5;fi;
cd $ROOT
DIR="$(ls)"
for dir in $DIR
        do
            if [[ ! -d "$DEST/$dir" ]]; then
                mkdir -p "$DEST/$dir"
                echo $ROOT$dir
                echo "$DEST/$dir"
	    fi

  	    if [[ ! -z $exPATH ]] && grep -q $dir $exPATH; then
		expath="$(grep $dir $exPATH)"
	    else
		expath=""
	    fi

            if [[ ! -z $inPATH ]] && grep -q $dir $inPATH; then
                inpath="$(grep $dir $inPATH)"
            else
                inpath=""
            fi

	    nice -n 19 duplicity remove-older-than 1M --no-encryption -v $vlevel "file://$DEST/$dir"

            case "$btype" in
                incremental)
                     nice -n 19 duplicity -v $vlevel $exclude $expath $include $inPATH --no-encryption $ROOT$dir "file://$DEST/$dir" | tee -a /var/log/duplicity-backup.log
                 ;;
                full)
	             nice -n 19 duplicity full -v $vlevel --no-encryption $exclude $expath $include $inPATH $ROOT$dir "file://$DEST/$dir" | tee -a /var/log/duplicity-backup.log
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

    [[ -d "$RES/$RES_FOLDER" ]] && rm -r "$RES/$RES_FOLDER"
    mkdir -p "$RES/$RES_FOLDER"
    if [[ -z "$vlevel" ]]; then vlevel=5;fi;
    if [[ -z "$restDay" ]]; then duplicity restore --no-encryption -v $vlevel "file://$DEST/$RES_FOLDER" "$RES/$RES_FOLDER";
    else duplicity restore -t $restDay --no-encryption -v $vlevel "file://$DEST/$RES_FOLDER" "$RES/$RES_FOLDER";
    fi

}

include_exclude(){

    if [[ ! -z "$EXCLUDE" ]]; then
      for x in "${EXCLUDE[@]}"; do
	eTMP="--exclude **\\$x "$eTMP
        exclude=$eTMP
      done
    fi

    if [[ ! -z "$INCLUDE" ]]; then
      for x in "${INCLUDE[@]}"; do
        iTMP="--include **\\$x "$iTMP
        include=$iTMP
      done
    fi
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

verify(){

	cd $ROOT
	DIR="$(ls)"
	for dir in $DIR; do
		duplicity verify --no-encryption "file://$DEST/$dir" $dir
	done
}

list_backups(){

        cd $ROOT
        DIR="$(ls)"
        for dir in $DIR; do
                duplicity collection-status "file://$DEST/$dir"
        done

}

do_nothing(){

echo "USAGE:
  $(basename "$0") [options]
  Options:
    -b   Backup webroot directory.
    -r   Restore the given site.
    -p	 Exclude list of directory provided by a file.
    -e	 Exclude type of files.
    -i	 Include type of file.
    -f	 Include list of directory provided by a file.
    -v	 Set verbosity level.
    -l	 List all backups.
    -c	 Check for all backup integrity.
    -d	 Restore according to the given time.
    -h	 Print this help file.

  Commands:
     $(basename "$0") -b full
     $(basename "$0") -b incremental
     $(basename "$0") -r name of site to be restored
     $(basename "$0") -p /path/to/file/with/directory/list
     $(basename "$0") -e *.log -e *.sql
     $(basename "$0") -i *.html -i *.php -i *.css
     $(basename "$0") -f /path/to/file/with/directory/list
     $(basename "$0") -v [0-9]. Default 5
     $(basename "$0") -l
     $(basename "$0") -c 
     $(basename "$0") -d Time format. To know allowed time format, checkout: http://duplicity.nongnu.org/duplicity.1.html#toc8

  Example:
     $(basename "$0") -e *.log -e *.sql -e *.txt -e *.mp4 -e *.js -e *.php -e *.html -p ${HOME}/file -b full
     $(basename "$0") -l
     $(basename "$0") -c
     $(basename "$0") -r
     $(basename "$0") -d 1D -r
"
}

### MAIN ###
check_duplicity_installed

[[ "$#" -eq "0" ]] && do_nothing;

while getopts "p:e:f:cli:v:d:b:r:" option; do
  case ${option} in
	l)
	    list_backups
	    ;;
	p)
	    exPATH=$OPTARG
	    ;;
        e)
            EXCLUDE=$OPTARG
	    include_exclude
            ;;
        f)
            inPATH=$OPTARG
            ;;
        i)
            INCLUDE=$OPTARG
	    include_exclude
            ;;
        v)
            vlevel=$OPTARG
            ;;
	c)
	    verify
	    ;;
	d)
	    restDay=$OPTARG
	    ;;
	b)
	    echo $(date) > /var/log/duplicity-backup.log
	    btype=$OPTARG
	    backup_webroot
	    ;;
	r)
            echo $(date) > /var/log/duplicity-backup.log
	    RES_FOLDER=$OPTARG
	    restore_webroot
	    ;;
	h)
	    do_nothing
	    ;;
	*)
	    do_nothing
	    ;;
  esac
done
