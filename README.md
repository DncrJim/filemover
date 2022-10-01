Development of bash code to automatically download remote files and folders as they are moved into a directory. Access is via sftp and process is designed to be executed by cron and run continuously

dependencies
lftp
bash

filemover.sh must be set to executable

#things to do
update automatic generation of config file, make sure to set permissions to 600 and user:group to user whose crontab will run process
should remote device url be prefixed with sftp in config?


##Setup instructions
#filemover_config.sh
create filemover_config.sh in the same directory as filemover.sh.
It is suggested to use home directory of user whose crontab will run process

#draft crontab
```
@reboot sleep 60 && /bin/bash ~/filemover.sh
```

#other
filemover.sh will create the following files and will overwrite them if they exist
filemover.log  - not yet implimented
filemover.list  - complete list of all downloaded files (stops repeat downloads)
filemover.queue - files which have been set for download but not yet completed
filemover.temp - temporary file used to compare existing and previously downloaded files
