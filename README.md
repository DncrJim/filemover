Development of bash code to automatically download remote files and folders as they are moved into a directory. Access is via sftp and process is designed to be executed by cron and run continuously

lftp is a dependency

#things to check/confirm
should remote device url be prefixed with sftp in config?


##Setup instructions
#filemover_config.sh
create filemover_config.sh in the same directory as filemover.sh.
It is suggested to use home directory of user whose crontab will run process

template for filemover_config.sh:

```
host_url='sftp://ftp.domain.com'
host_user=''
host_pass=''

remote_dir=''  #unknown if needs trailing slash
local_dir=''  #needs trailing slash

path_to_list='filemover.list'
path_to_queue='filemover.queue'
```

make sure to set permissions to 600 and user:group to user whose crontab will run process



#draft crontab
needs wait added after reboot
needs to have a periodic check to see if task is running and restart if not
```
@reboot /bin/bash ~/filemover.sh
```

#other
filemover.list will be created automatically which is used to save the names of all files/folders which have been moved to create a differential list.
filemover.log will be created. as a log.
filemover.temp and filemover.queue may also be created

don't forget that original filemover.sh needs to be set to executable
