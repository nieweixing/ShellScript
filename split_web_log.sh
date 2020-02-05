#!/bin/bash

split_log(){

	date_time=`date +%m%d%H%M%S`
    log_date=`date "+%Y-%m-%d %H:%M:%S"`
	
    if [ ! -f $basepath/*.log.crn ];then
        echo "[$log_date] There is no log file ending with log.crn in the path."
        exit 0
    fi
    filename=`ls -l $basepath/*.log.crn | awk '{ print $NF }' | awk -F "/" '{print $NF}'`
    filesize=`ls -l $basepath/*.log.crn | awk '{ print $5 }'`
    maxsize=$((1024*1024*50))
    system_name=`echo $filename | awk -F "-" '{print $1}'`
    modename=`echo $filename | awk -F "-" '{print $2}'`
    containId_or_ip=`echo $filename | awk -F "-" '{print $NF}'`
    containId_or_ip_name=`echo ${containId_or_ip%.log*}`
    split_name=$system_name-$modename-$containId_or_ip_name-$date_time.log
    if [ $filesize -gt $maxsize ]; then
        mv $basepath/$filename $basepath/$split_name
        echo "[$log_date] Log split succeeded,Pre-cut name $filename,Post-cut name $split_name"
        exit 0
    fi
    echo "[$log_date] The log size is less than 50M and does not need to be split."
}

main(){
    basepath=/logs/current/kgap
	if [ ! -d $basepath ];then
		echo "[$log_date] Log directory /logs/current/kgap does not exist"
		exit 0
	fi
    #Log cutting, cut by file size (greater than 50M)
    split_log
}

main
