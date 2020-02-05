#!/bin/bash

##############################################################################################################################################
#   脚本修改使用说明
#   1.本脚本设置一个参数为redis的节点类型，根据输入的参数识别不同的redis节点，可以输入节点名或者节点ip
#   2.本脚本原始的日志路径输出到/data/datbase/$redis_node/这个目录，对应的名称为redis.log，这个/data/datbase/$1/redis.log是配置在redis.conf中
#   3.本脚本格式化后的日志路径为/logs/current/kgap/$redis_node/，对应的名称为kgap-redis-$redis_node.log.crn,
#     日志切割后的日志名为kgap-redis-$redis_node.1107153341.log，切割大小为50M
#   4.脚本的crontab配置方式,例如脚本放到/opt目录下,脚本的执行日志可以输出也可以不输出
#     crontab -e 编辑crontab
#     输出脚本执行日志
#     * * * * * sh /opt/redis_log.sh redis_node >> redis_log_[redis_node].log
#     * * * * * sh /opt/redis_log.sh redis_node >> redis_log_[redis_node].log
#     不输出脚本执行日志
#	  * * * * * sh /opt/redis_log.sh redis_node
#     * * * * * sh /opt/redis_log.sh redis_node 
#
##############################################################################################################################################


workdir=$(cd $(dirname $0); pwd)
date_time=`date +%m%d%H%M%S`
log_record_date=`date "+%Y-%m-%d %H:%M:%S"`

redis_node=$1
base_dir="/data/datbase/redis/$redis_node/"
original_log="redis.log"
tmp_log="redis_tmp_$date_time.log"
After_format_dir="/logs/current/kgap/redis/$redis_node/"
After_format_log="kgap-redis-$redis_node.log.crn"

if [ "X$1" = "X" ];then
    echo "Parameter input error, please enter -h to view help"
	exit 0
fi

if [ "X$1" = "X-h" ];then
	echo "Please enter the name of the redis node you want to process the log as, for example
sh [script_name] [node_name]
sh redis_log.sh master/master-ip
sh redis_log.sh redis1/redis1-ip"
    exit 0
fi

#Cut the formatted log
split_log()
{
    filename=`ls -l $After_format_dir*.log.crn | awk '{ print $NF }' | awk -F "/" '{print $NF}'`
    filesize=`ls -l $After_format_dir*.log.crn | awk '{ print $5 }'`
    maxsize=$((1024*1024*50))
    system_name=`echo $filename | awk -F "-" '{print $1}'`
    modename=`echo $filename | awk -F "-" '{print $2}'`
    containId_or_ip=`echo $filename | awk -F "-" '{print $NF}'`
    containId_or_ip_name=`echo ${containId_or_ip%.log*}`
    split_name=$system_name-$modename-$containId_or_ip_name-$date_time.log
    if [ $filesize -gt $maxsize ]; then
        mv $After_format_dir$filename $After_format_dir$split_name
        echo "[$redis_node] [$log_record_date] Log split succeeded,Pre-cut name $filename,Post-cut name $split_name"
    fi
    echo "[$redis_node] [$log_record_date] The log size is less than 50M and does not need to be split."
}



main()
{
if [ ! -d "$base_dir" ];then
	echo "[$redis_node] [$log_record_date] The log directory $base_dir not exist,Please create a directory"
	exit 0
fi

if [ ! -d "$After_format_dir" ];then
	echo "[$redis_node] [$log_record_date] The log directory $After_format_dir not exist,Please create a directory"
	exit 0
fi


if [ -f $base_dir$original_log ];then
	mv $base_dir$original_log $base_dir$tmp_log
else
	echo "[$redis_node] [$log_record_date] The redis original log does not exist and Ensure that the original log of redis is output to the directory $base_dir "
	exit 0
fi

while read line
do
   if [ -f $After_format_dir*.log.crn ];then
        split_log
   else     
      echo "[$redis_node] [$log_record_date] There is no log file ending with log.crn in the path."
   fi
   
   if [ "X$line" = "X" ];then
      continue
   fi
 
   first_character=`echo ${line:0:1}`
   if [[ "X$first_character" = "X" ]] || [[ "X$first_character" = "X_" ]] || [[ "X$first_character" = "X." ]] || [[ "X$first_character" = "X(" ]] || [[ "X$first_character" = "X|" ]] || [[ "X$first_character" = "X\`" ]];then
       echo "$line" >> $After_format_dir$After_format_log
       continue
   else
      log_content=`echo "$line" | awk '{for (i=7 ;i<=NF;i++) printf $i " "; printf "\n" }'`
      log_date=`echo "$line" | awk '{for (i=1 ;i<=5;i++) printf $i " "; printf "\n" }'`
      log_level=`echo "$line" | awk '{print $6}'`
	  log_day=`echo "$line" | awk '{print $2}'`
	  echo "$log_day" | grep "(" >/dev/null
      if [ "X$?" = "X0" ];then
	      echo "$line" >> $After_format_dir$After_format_log
		  continue
	  fi
      if [ "X$log_level" = "X." ];then
         echo "$log_date [DEBUG] $log_content" >> $After_format_dir$After_format_log
      elif [ "X$log_level" = "X-" ];then
         echo "$log_date [VERBOSE] $log_content" >> $After_format_dir$After_format_log
      elif [ "X$log_level" = "X*" ];then
         echo "$log_date [NOTICE] $log_content" >> $After_format_dir$After_format_log
      elif [ "X$log_level" = "X#" ];then
         echo "$log_date [WARNING] $log_content" >> $After_format_dir$After_format_log
      else
	     continue
	  fi

   fi
    
done < $base_dir$tmp_log

if [ -f "$base_dir$tmp_log" ];then
   rm -rf $base_dir$tmp_log
fi

}

main