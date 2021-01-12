#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

# get the path to this script
APP_PATH=`dirname "$0"`
APP_PATH=`( cd "$APP_PATH" && pwd )`

unattended=0
subinstall_params=""
for param in "$@"
do
  echo $param
  if [ $param="--unattended" ]; then
    echo "installing in unattended mode"
    unattended=1
    subinstall_params="--unattended"
  fi
done

distro=`lsb_release -r | awk '{ print $2 }'`

default=y
while true; do
  if [[ "$unattended" == "1" ]]
  then
    resp=$default
  else
    [[ -t 0 ]] && { read -t 10 -n 2 -p $'\e[1;32mInstall NEOVIM? [y/n] (default: '"$default"$')\e[0m\n' resp || resp=$default ; }
  fi
  response=`echo $resp | sed -r 's/(.*)$/\1=/'`

  if [[ $response =~ ^(y|Y)=$ ]]
  then

    echo Installing neovim

    if [ "$distro" = "18.04" ]; then
      sudo apt-add-repository -y ppa:neovim-ppa/stable
      sudo apt-get update
    fi

    sudo apt-get -y install neovim
    mkdir -p ~/.config/nvim/

    if [ "$distro" = "18.04" ]; then
      sudo -H pip install wheel
    fi
    sudo -H pip3 install wheel

    sudo -H pip3 install neovim
    sudo -H pip3 install neovim-remote

    # link the configuration
    ln -sf ~/.vimrc ~/.config/nvim/init.vim
    ln -sf $APP_PATH/../vim/dotvim/* ~/.config/nvim/

    break
  elif [[ $response =~ ^(n|N)=$ ]]
  then
    break
  else
    echo " What? \"$resp\" is not a correct answer. Try y+Enter."
  fi
done
