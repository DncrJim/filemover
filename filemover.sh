#!/bin/sh

#create config file if it doesn't exist
    if [ ! -f "filemover_config.sh" ] ; then
      echo "host_url='sftp://ftp.domain.com'\nhost_user=''\nhost_pass=''\n\nremote_dir=''  #unknown if needs trailing slash\nlocal_dir=''  #needs trailing slash\n\npath_to_list='filemover.list'  #should include the file name you want to use\npath_to_queue='filemover.queue'  #should include the file name you want to use" > filemover_config.sh
      echo "filemover_config.sh created, please edit the file to input your variables"
     exit 0
   fi

#load config file variables
   . ~/filemover_config.sh

#if filemover.list doesn't exist, create it
   if [ ! -f "$path_to_list" ] ; then
     touch $path_to_list
     echo "filemover.list created"
   fi

#get remote list of files in directory
lftp -u $host_user,$host_pass $host_url <<EOF
ls files | cut -c 44- | grep -v ".meta" > filemover.temp
exit
EOF

#compare remote list of files to local list of files already downloaded and add missing to queue
#note specific evocation of bash command because of the file substitution for sort
`bash -c "comm -13 <(sort -u < "filemover.list") <(sort -u < "filemover.temp") >> filemover.queue" ` ;

#remove temp list of files
rm filemover.temp

#download files in queue
while true
  do
        read -r filepath < "$path_to_queue"

      #if $filepath is empty, break loop
      if [[ -z "$filepath" ]] ; then
          break
      else

      #if filepath has one of these endings, use get, otherwise use mirror.
          if [[ $file == *.mkv || $file == *.mp4 ]] ; then
            # || ( $file == *.avi ) || ( $file == *.webm ) || ( $file == *.flv ) || ( $file == *.vob ) || ( $file == *.mts ) || ( $file == *.m2ts ) || ( $file == *.ts ) || ( $file == *.mov ) || ( $file == *.wmv ) || ( $file == *.m4p ) || ( $file == *.m4v ) || ( $file == *.mpg ) || ( $file == *.mpeg )
              echo "determined to be file, using get"
              lftp -u $host_user,$host_pass -e "get -c '$remote_dir$filepath' -o '$local_dir$filepath';quit;" $host_url
          else
              echo "determined to be folder, using mirror"
              lftp -u $host_user,$host_pass -e "mirror -c --parallel=3 --verbose '$remote_dir$filepath' $local_dir;quit;" $host_url
          fi
      fi
    #confirm no error on transfer
      if [ $? -ne 0 ] ; then
          echo "error mv $filepath"
        else
          echo "success $filepath"
          echo "$filepath" >> $path_to_list
        #delete line from queue
          sed -i 1d $path_to_queue
      fi
    done



		if [ ! -s $path_to_queue ] ; then
      echo "queue is empty!"
    else
      echo "queue is not empty!"
    fi

exit 0
