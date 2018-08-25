#/bin/bash

cd ~
echo "****************************************************************************"
echo "* Ubuntu 16.04 is the recommended opearting system for this install.       *"
echo "*                                                                          *"
echo "* This script will install and configure your Transcendence  masternodes.  *"
echo "****************************************************************************"
echo && echo && echo
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!                                                 !"
echo "! Make sure you double check before hitting enter !"
echo "!                                                 !"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo && echo && echo

echo "Is this your first Transcendence masternode? [y/n]"
read DOSETUP
echo ""
echo "What interface do you want to use? (4 For ipv4 or 6 for ipv6)"
read INTERFACE
echo ""
IP4=$(curl -s4 api.ipify.org)
IP6=$(curl v6.ipv6-test.com/api/myip.php)
wget https://github.com/Lagadsz/Transcendence-Dynamic-Chain/releases/download/v0.1/DynamicChain.zip

if [ $DOSETUP = "y" ]
then
  echo "iface ens3 inet6 static" >> /etc/network/interfaces
  echo "address $IP6" >> /etc/network/interfaces
  echo "netmask 64" >> /etc/network/interfaces
  sudo apt-get update
  sudo apt-get -y upgrade
  sudo apt-get -y dist-upgrade
  sudo apt-get update
  sudo apt-get install -y zip unzip

  cd /var
  sudo touch swap.img
  sudo chmod 600 swap.img
  sudo dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
  sudo mkswap /var/swap.img
  sudo swapon /var/swap.img
  sudo free
  sudo echo "/var/swap.img none swap sw 0 0" >> /etc/fstab
  cd

  wget https://github.com/phoenixkonsole/transcendence/releases/download/v1.1.0.0/Linux.zip
  unzip Linux.zip
  chmod +x Linux/bin/*
  sudo mv  Linux/bin/* /usr/local/bin
  rm -rf Linux.zip Windows Linux Mac

  sudo apt-get install -y ufw
  sudo ufw allow ssh/tcp
  sudo ufw limit ssh/tcp
  sudo ufw logging on
  echo "y" | sudo ufw enable
  sudo ufw status

  mkdir -p ~/bin
  echo 'export PATH=~/bin:$PATH' > ~/.bash_aliases
  source ~/.bashrc
  echo ""
fi

 ## Setup conf
if [ $INTERFACE = "4" ]
then
echo ""
echo "How many nodes do you want to create on this server? [min:1 Max:20]  followed by [ENTER]:"
read MNCOUNT
let MNCOUNT=MNCOUNT+1
let COUNTER=1
while [  $COUNTER -lt $MNCOUNT ]; do
 PORT=22123
 echo "What port do you want to use? (Usually 22123)"
 read PORTD
 RPCPORTT=$(($PORT*10))
 RPCPORT=$(($RPCPORTT+$COUNTER))
  echo ""
  echo "Enter alias for new node"
  read ALIAS
  CONF_DIR=~/.transcendence_$ALIAS
  echo ""
  echo "Enter masternode private key for node $ALIAS"
  read PRIVKEY
  mkdir ~/.transcendence_$ALIAS
  unzip DynamicChain.zip -d ~/.transcendence_$ALIAS
  echo '#!/bin/bash' > ~/bin/transcendenced_$ALIAS.sh
  echo "transcendenced -daemon -conf=$CONF_DIR/transcendence.conf -datadir=$CONF_DIR "'$*' >> ~/bin/transcendenced_$ALIAS.sh
  echo '#!/bin/bash' > ~/bin/transcendence-cli_$ALIAS.sh
  echo "transcendence-cli -conf=$CONF_DIR/transcendence.conf -datadir=$CONF_DIR "'$*' >> ~/bin/transcendence-cli_$ALIAS.sh
  echo '#!/bin/bash' > ~/bin/transcendence-tx_$ALIAS.sh
  echo "transcendence-tx -conf=$CONF_DIR/transcendence.conf -datadir=$CONF_DIR "'$*' >> ~/bin/transcendence-tx_$ALIAS.sh
  chmod 755 ~/bin/transcendence*.sh
  mkdir -p $CONF_DIR
  echo "rpcuser=user"`shuf -i 100000-10000000 -n 1` >> transcendence.conf_TEMP
  echo "rpcpassword=pass"`shuf -i 100000-10000000 -n 1` >> transcendence.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> transcendence.conf_TEMP
  echo "rpcport=$RPCPORT" >> transcendence.conf_TEMP
  echo "listen=1" >> transcendence.conf_TEMP
  echo "server=1" >> transcendence.conf_TEMP
  echo "daemon=1" >> transcendence.conf_TEMP
  echo "logtimestamps=1" >> transcendence.conf_TEMP
  echo "maxconnections=256" >> transcendence.conf_TEMP
  echo "masternode=1" >> transcendence.conf_TEMP
  echo "" >> transcendence.conf_TEMP

  echo "" >> transcendence.conf_TEMP
  echo "port=$PORT" >> transcendence.conf_TEMP
  echo "masternodeaddr=$IP4:$PORT" >> transcendence.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> transcendence.conf_TEMP
  sudo ufw allow $PORT/tcp
  mv transcendence.conf_TEMP $CONF_DIR/transcendence.conf 
  COUNTER=$((COUNTER+1))
done
fi




if [ $INTERFACE = "6" ]
then
echo ""
echo ""
echo "How many nodes do you want to create on this server? [min:1 Max:20]  followed by [ENTER]:"
read MNCOUNT
let MNCOUNT=MNCOUNT+1
let COUNTER=1
 while [  $COUNTER -lt $MNCOUNT ]; do
 echo "up /sbin/ip -6 addr add dev ens3 ${IP6:0:18}::$COUNTER" >> /etc/network/interfaces
 PORT=22123 
 RPCPORTT=$(($PORT*10))
 RPCPORT=$(($RPCPORTT+$COUNTER))
    echo ""
  echo "Enter alias for new node"
  read ALIAS
  CONF_DIR=~/.transcendence_$ALIAS
  echo ""
  echo "Enter masternode private key for node $ALIAS"
  read PRIVKEY
  mkdir ~/.transcendence_$ALIAS
  unzip DynamicChain.zip -d ~/.transcendence_$ALIAS
  echo '#!/bin/bash' > ~/bin/transcendenced_$ALIAS.sh
  echo "transcendenced -daemon -conf=$CONF_DIR/transcendence.conf -datadir=$CONF_DIR "'$*' >> ~/bin/transcendenced_$ALIAS.sh
  echo '#!/bin/bash' > ~/bin/transcendence-cli_$ALIAS.sh
  echo "transcendence-cli -conf=$CONF_DIR/transcendence.conf -datadir=$CONF_DIR "'$*' >> ~/bin/transcendence-cli_$ALIAS.sh
  echo '#!/bin/bash' > ~/bin/transcendence-tx_$ALIAS.sh
  echo "transcendence-tx -conf=$CONF_DIR/transcendence.conf -datadir=$CONF_DIR "'$*' >> ~/bin/transcendence-tx_$ALIAS.sh
  chmod 755 ~/bin/transcendence*.sh
  mkdir -p $CONF_DIR
  echo "rpcuser=user"`shuf -i 100000-10000000 -n 1` >> transcendence.conf_TEMP
  echo "rpcpassword=pass"`shuf -i 100000-10000000 -n 1` >> transcendence.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> transcendence.conf_TEMP
  echo "rpcport=$RPCPORT" >> transcendence.conf_TEMP
  echo "listen=1" >> transcendence.conf_TEMP
  echo "server=1" >> transcendence.conf_TEMP
  echo "daemon=1" >> transcendence.conf_TEMP
  echo "logtimestamps=1" >> transcendence.conf_TEMP
  echo "maxconnections=256" >> transcendence.conf_TEMP
  echo "masternode=1" >> transcendence.conf_TEMP
  echo "" >> transcendence.conf_TEMP

  echo "" >> transcendence.conf_TEMP
  echo "bind=[${IP6:0:18}::$COUNTER]" >> transcendence.conf_TEMP
  echo "port=$PORT" >> transcendence.conf_TEMP
  echo "masternodeaddr=[${IP6:0:18}::$COUNTER]:$PORT" >> transcendence.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> transcendence.conf_TEMP
  sudo ufw allow $PORT/tcp
  mv transcendence.conf_TEMP $CONF_DIR/transcendence.conf 
  COUNTER=$((COUNTER+1))
done
fi
systemctl restart networking.service
rm DynamicChain.zip
exit

