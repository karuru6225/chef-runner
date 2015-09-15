#!/bin/bash

usage_exit() {
  echo "Usage: $0 [-u] [-y|-n] [-h] -j {chef node file} -t {target dir} -l {debug|info|warn|error|fatal}" 1>&2
  echo "-u update cookbooks"
  echo "-y don't confirm actually run"
  echo "-n only why-run"
  echo "-h show this help"
  echo "-j {node file}"
  echo "-l {loglevel}"
  echo "-t {target directory}"
  exit 1
}

YES=0
UPDATE=0
NO=0
NODE=''
LEVEL=''
DIR=''

while getopts yuhj:l:nt: OPT
do
  case $OPT in
    y)  YES=1
      ;;
    u)  UPDATE=1
      ;;
    h)  usage_exit
      ;;
    j)  NODE=$OPTARG
      ;;
    l)  LEVEL=$OPTARG
      ;;
    n)  NO=1
      ;;
    t)  DIR=$OPTARG
      ;;
  esac
done

if [ "$NODE" = "" -a $UPDATE = 0 ]; then
  usage_exit
fi

if [ ! "$DIR" = "" ]; then
  cd "$DIR"
fi

if [ ! -d '.chef' ]; then
  mkdir .chef
fi

if [ ! -f '.chef/knife.rb' ]; then
  cat << _EOF_ > .chef/knife.rb
local_mode true

chef_repo_dir = File.absolute_path( File.dirname(__FILE__) + "/.." )

cookbook_path    ["#{chef_repo_dir}/cookbooks", "#{chef_repo_dir}/site-cookbooks"]
node_path        "#{chef_repo_dir}/nodes"
role_path        "#{chef_repo_dir}/roles"
environment_path "#{chef_repo_dir}/environments"
data_bag_path    "#{chef_repo_dir}/data_bags"
#encrypted_data_bag_secret "#{chef_repo_dir}/data_bag_key"

knife[:berkshelf_path] = "#{chef_repo_dir}/cookbooks"
_EOF_
fi

if [ ! -d 'cookbooks' ]; then
  berks vendor cookbooks 
fi
if [ $UPDATE = "1" ];
then
  berks update && berks vendor cookbooks 
fi

if [ "$NODE" = "" ]; then
  exit 0
fi

if [ ! $YES = "1" ];
then
  if [ "$LEVEL" = "" ];
  then
    chef-solo -c .chef/knife.rb -j "${NODE}" --why-run
  else
    chef-solo -c .chef/knife.rb -j "${NODE}" --why-run --log_level $LEVEL
  fi
fi
if [ $NO = "1" ];then
  exit 0
fi
if [ ! $YES = "1" ];
then
  echo -n "run? (y/N): "
  read INPUT
fi
if [ "${INPUT}" = "y" -o "${INPUT}" = "Y" -o $YES = "1" ];
then
  if [ "$LEVEL" = "" ];
  then
    chef-solo -c .chef/knife.rb -j "${NODE}"
  else
    chef-solo -c .chef/knife.rb -j "${NODE}" --log_level $LEVEL
  fi
fi

