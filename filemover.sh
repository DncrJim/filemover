#!/bin/bash

#create config file if it doesn't exist
    if [ ! -f "filemover_config.sh" ] ; then
      echo "host_url='sftp://ftp.domain.com'  #confirmed with ftp:, not confirmed with sftp:, https:, use alternate under 'get remote list'"  > filemover_config.sh
      echo "host_user=''" >> filemover_config.sh
      echo "host_pass=''" >> filemover_config.sh
      echo "" >> filemover_config.sh
      echo "remote_dir=''  #needs trailing slash" >> filemover_config.sh
      echo "local_dir=''  #needs trailing slash" >> filemover_config.sh
      echo "" >> filemover_config.sh
      echo "path_to_list='filemover.list'  #should include the file name you want to use" >> filemover_config.sh
      echo "path_to_queue='filemover.queue'  #should include the file name you want to use" >> filemover_config.sh
      echo "filemover_config.sh created, please insert the values for all variables and run again."
     exit 0
   fi

#load config file variables
   . ~/filemover_config.sh

#if filemover.list doesn't exist, create it
   if [[ ! -f "$path_to_list" ]] ; then
     touch "$path_to_list"
     echo "filemover.list created"
   fi

#set all variables to 0
error_queue_not_empty=0
tried_to_process_file=0
transfer_error_count=0


while true
do

  #get remote list of files in directory
  lftp -u $host_user,$host_pass $host_url <<EOF
  ls -1 $remote_dir | grep -v ".meta" > filemover.temp
  #use this option if https: instead of ftp: ls $remote_dir | cut -c 44- | grep -v ".meta" > filemover.temp
  exit
EOF

  #compare remote list of files to local list of files already downloaded and add missing to queue
  #note specific evocation of bash command because of the file substitution for sort
  comm -13 <(sort -u < "filemover.list") <(sort -u < "filemover.temp") >> filemover.queue

  #remove temp list of files
  rm filemover.temp

  #download files in queue
  while true
    do
        read -r filepath < "$path_to_queue"

      #if $filepath is empty, remove row, and try again
      if [[ -z "$filepath" ]] ; then
          sed -i 1d "$path_to_queue"
          read -r filepath < "$path_to_queue"
      fi

      #if filepath is empty, remove row, try again
      if [[ -z "$filepath" ]] ; then
          sed -i 1d "$path_to_queue"
          read -r filepath < "$path_to_queue"
      fi

      #if filepath is empty, break while
      if [[ -z "$filepath" ]] ; then
          break
      else
          tried_to_process_file=1


      #if filepath has one of these endings, use get, otherwise use mirror.
          if [[ "$filepath" =~ .*\.(mp4|mkv|avi|webm|flv|vob|mts|m2ts|ts|mov|wmv|m4p|m4v|mpg|mpeg) ]] ; then
              lftp -u $host_user,$host_pass -e "get -c \"$remote_dir$filepath\" -o \"$local_dir$filepath\" ; quit;" $host_url
          else
              lftp -u $host_user,$host_pass -e "mirror -c --parallel=3 --verbose \"$remote_dir$filepath\" \"$local_dir\" ; quit;" $host_url
          fi
      fi
    #confirm no error on transfer
      if [[ $? -ne 0 ]] ; then

          #increase counter by 1
          transfer_error_count++

          if [ $transfer_error_count == 1 ]; then
              echo "error moving $filepath!\nThis message will not be sent again until all files are removed from queue.\nThis may not be the only file throwing an error" | mail -s "filemover ERROR" root
          fi

          #copy first line of queue to end of queue and then remove from first line of queue, rotating error to the bottom
          echo "$filepath" >> "$path_to_queue"
          sed -i 1d "$path_to_queue"

          # if there have been more than 3 errors since the last time the queue was empty, it will wait one hour after each additional error until queue empty
          if [[ $transfer_error_count -ge 3 ]]; then sleep 3600; fi

      else
          echo "success $filepath" | mail -s "filemover success" root
          echo "$filepath" >> "$path_to_list"
          #delete line from queue
          sed -i 1d "$path_to_queue"
      fi
      sleep 10
  done


	if [[ ! -s "$path_to_queue" ]] ; then
    if [ $tried_to_process_file == 1 ]; then echo "filemover reached end and queue is empty!" | mail -s "filemover success" root; fi

  else
    if [ $error_queue_not_empty == 0 ]; then echo "filemover reached end and queue is not empty!\nNote: this message will not send again until program has been restarted." | mail -s "filemover ERROR" root; fi
    error_queue_not_empty=1
  fi

tried_to_process_file=0
transfer_error_count=0

sleep 600  #10 minutes
done
