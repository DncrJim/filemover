Script to check and compare remote folder to list of files and directories and download anything which has not be downloaded in the past. Access is via ftp, script is designed to start at system startup (cron) and run continuously.

dependencies
lftp
bash


## To Do
create error reporting if lftp can't retrieve directory listing  
update automatic generation of config file,  
should remote device url be prefixed with sftp in config?
need instructions for adding ca-certificate, or see how to generate user interactive prompt  

## Setup
### filemover_config.sh
create filemover_config.sh in the same directory as filemover.sh.
It is suggested to use home directory of user whose crontab will run process


## Other Notes
make sure to set permissions to 600 and user:group to user whose crontab will run process  
filemover.sh must be set to executable
filemover.sh will create the following files and will overwrite them if they exist:
  filemover.log  - not yet implemented  
  filemover.list  - complete list of all downloaded files (stops repeat downloads)  
  filemover.queue - files which have been set for download but not yet completed  
  filemover.temp - temporary file used to compare existing and previously downloaded files  
