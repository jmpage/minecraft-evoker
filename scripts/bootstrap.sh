#!/bin/bash -x

USERNAME='minecraft'
MC_HOME="/home/$USERNAME"
REMOTE_SERVER_FILE=`cat /var/lib/cloud/data/server_filename`
BUCKET_NAME=`cat /var/lib/cloud/data/bucket_name`
SERVER_NAME=`cat /var/lib/cloud/data/server_name`

install_updates() {
  sudo yum update -y
}

download_server() {
  local remote_dir="s3://$BUCKET_NAME/common/servers/"
  if (aws s3 ls $remote_dir | grep -Fq "$REMOTE_SERVER_FILE"); then
    local local_file="$MC_HOME/server.jar"
    local remote_file="s3://$BUCKET_NAME/common/servers/$REMOTE_SERVER_FILE"
    echo "Downloading server from $remote_file"
    aws s3 cp $remote_file $local_file
    chown $USERNAME $local_file
  else
    echo "Server file not found in bucket."
    exit 1
  fi
}

download_world() {
  mkdir -p $MC_HOME/backups
  chown -R $USERNAME $MC_HOME/backups
  local remote_dir="s3://$BUCKET_NAME/servers/$SERVER_NAME/world_backups/"
  local file_name='current.tgz'
  if (aws s3 ls $remote_dir | grep -Fq "$file_name"); then
    local local_file="/tmp/world.tgz"
    echo "Found latest world backup. Downloading."
    aws s3 cp "$remote_dir$file_name" "$local_file"
    tar -xzf "$local_file" -C "$MC_HOME"
    rm $local_file
    chown -R $USERNAME "$MC_HOME/world"
  else
    echo "No world backup found. Skipping."
  fi
}

download_configs() {
  local remote_dir="s3://$BUCKET_NAME/servers/$SERVER_NAME/configs/"
  aws s3 ls $remote_dir > /tmp/s3-config-list.tmp
  for file in "banned-ips.json" "banned-players.json" "ops.json" "server.properties" "whitelist.json" "eula.txt"; do
    if (cat /tmp/s3-config-list.tmp | grep -Fq "$file"); then
      local local_file="$MC_HOME/$file"
      echo "Copying $file from s3 to $MC_HOME"
      aws s3 cp "$remote_dir$file" "$local_file"
      chown $USERNAME "$local_file"
    fi
  done
}

configure_subsystem() {
  local local_file="/etc/init.d/minecraft"
  if [ -f $local_file ]; then
    echo "Subsystem already exists. Stopping."
    exit 1
  else
    local remote_file="s3://$BUCKET_NAME/common/scripts/init"
    echo "Subsystem not found. Downloading from $remote_file"
    aws s3 cp $remote_file $local_file
    chmod 755 $local_file
    chkconfig --add minecraft
    service minecraft start
    chkconfig minecraft on
  fi
}

add_crontab_line() {
  local line=$1
  if (crontab -u $USERNAME -l | grep -Fq "$line"); then
    echo "Backups already in crontab. Skipping."
  else
    echo "Appending backup command to crontab."
    (crontab -u $USERNAME -l; echo "$line" ) | crontab -u $USERNAME -
  fi
}

configure_crontab() {
  add_crontab_line "*/5 * * * * /etc/init.d/minecraft start"
  add_crontab_line "0,30 * * * * /etc/init.d/minecraft backup_world"
  add_crontab_line "1,31 * * * * /etc/init.d/minecraft backup_config"
  add_crontab_line "10 0 * * * /etc/init.d/minecraft backup_copy"
}

associate_eip() {
  aws ec2 --region us-east-1 associate-address --instance-id `cat /var/lib/cloud/data/instance-id` --allocation-id `cat /var/lib/cloud/data/eip`
}

install_updates
download_server
download_world
download_configs
configure_subsystem
configure_crontab
associate_eip

exit 0
