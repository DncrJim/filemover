#!/bin/bash

#create config file if it doesn't exist
    if [ ! -f "filemover_config.sh" ] ; then
      echo "host_url='sftp://ftp.domain.com'"  > filemover_config.sh
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

#generate variable for error code only if it hasn't already been set
  if [[ ! -v $has_thrown_queue_error_b4 ]] ; then
    has_thrown_queue_error_b4=0
  fi

while true
do

  #get remote list of files in directory
  lftp -u $host_user,$host_pass $host_url <<EOF
  ls $remote_dir | cut -c 44- | grep -v ".meta" > filemover.temp
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

      #if filepath is empty, break loop
      if [[ -z "$filepath" ]] ; then
          break
      else
          tried_to_process_file=1
      #if filepath has one of these endings, use get, otherwise use mirror.
          if [[ "$filepath" =~ .*\.(mp4|mkv|avi|webm|flv|vob|mts|m2ts|ts|mov|wmv|m4p|m4v|mpg|mpeg) ]] ; then
              lftp -u $host_user,$host_pass -e 'get -c "${remote_dir}${filepath}" -o "${local_dir}${filepath}";quit;' $host_url
          else
              lftp -u $host_user,$host_pass -e 'mirror -c -parallel=3 --verbose "{$remote_dir}${filepath}" "${local_dir}";quit;' $host_url
          fi
      fi
    #confirm no error on transfer
      if [[ $? -ne 0 ]] ; then
          echo "error mv $filepath" | mail -s "filemover ERROR" root

          #should set variable so that sleep only happens if error occurs two times in a row

          #copy first line of queue to end of queue
          echo "$filepath" >> "$path_to_queue"
          #delete first line from queue
          sed -i 1d "$path_to_queue"
          sleep 600

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
    if [ $has_thrown_queue_error_b4 == 0 ]; then echo "filemover reached end and queue is not empty!" | mail -s "filemover ERROR" root; fi
    has_thrown_queue_error_b4=1
  fi

tried_to_process_file=0
sleep 600
done
