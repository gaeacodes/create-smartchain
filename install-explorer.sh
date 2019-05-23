#!/bin/bash

source data

if [ ! -f "/home/$USER/.komodo/$name/$name.conf" ]; then
  echo "create the assetchain with name: $name and shut down the daemons before trying to install the explorer"
  echo "Exiting"
  exit 1  
fi


pidfile="$HOME/.komodo/$name/komodod.pid"  

if [ -f $pidfile ]; then
  echo "The first daemon is running, it needs to be shutdown to install the explorer"
  echo "This script will now try to shut down the daemon"
  read -p "Should we proceed? (y/n) "  answer
  while [ "answer" != "y" ] && [ "answer" != "n" ]; do
    echo "Please answer either 'y' for yes or 'n' for no"
    read -p "Should we proceed? (y/n) "  answer
  done
  
  if [ "answer" -eq "n" ]; then
    echo "Exiting the script, please shutdown the first daemon using './c1 stop' and try again"
    exit 1
  elif [ "answer" -eq "y" ]; then
    echo "Proceeding to shut down the daemon and install the explorer"
    ./c1 stop
    while ./c1 stop &>/dev/null
    do
      echo "waiting for the first daemon to stop"
      sleep 5
    done
    echo "first daemon has been stopped"
  fi
else
  echo "First daemon is not running"
fi

echo "Proceeding to install the explorer"

echo "Cloning the explorer installer repository"
git clone https://github.com/gcharang/komodo-install-explorer.git explorers

cd explorers
if [ ! -d "./node_modules/bitcore-node-komodo" ]; then
  echo "Setting up the explorer directory and installing dependencies" 
  ./setup-explorer-directory.sh
else
  echo "Looks like the initial setup of the explorers directory and installation of dependencies has been done"
fi

./install-assetchain-explorer.sh $name noweb

echo "Launching first daemon to reindex the blocks"
cd ..

gnome-terminal -e "bash -c \"echo '$launch -pubkey=$pubkey1 -reindex'; $srcdir/$launch -pubkey=$pubkey1 -reindex; exec bash\""
echo "started the first daemon in a new terminal with '-reindex'"
echo "waiting for reindexing to finish"
tail -f /home/$USER/.komodo/$name/debug.log & | while read LOGLINE
do
  [[ "${LOGLINE}" == *"Reindexing finished"* ]] && pkill -P $$ tail
done
echo "the daemon has finished reindexing; shutting down the daemon"
./c1 stop
while ./c1 stop &>/dev/null
do
  echo "waiting for the first daemon to stop"
  sleep 5
done

echo "Use the 'start.sh' script to start the daemons"