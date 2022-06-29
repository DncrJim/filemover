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
lftp -u $host_user,$host_pass $host_url <<EOF

mirror "$remote_dir" $local_dir;

exit
EOF


  #determine if file or folders
  #if file use get command
  #if folder use mirror command

  #confim if file downloaded correctly?
  #remove file/folder from queue and add to filemover.list

#wait preset time before repeating from top - maybe 10 minutes?
#sleep 60
#repeat
