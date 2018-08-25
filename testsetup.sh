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
echo "Enter alias for new node"
read ALIAS

if [ $DOSETUP = "y" ]
then
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
  echo "Enter alias for new node"
  read ALIAS
fi

 ## Setup conf
 echo ""
 echo "What interface do you want to use? (4 For ipv4 or 6 for ipv6)"
 read INTERFACE
if [ $INTERFACE = "6" ]
then
 IP=$(curl v6.ipv6-test.com/api/myip.php)
 SUBIP6=${$IP:0:19}
 echo "iface ens3 inet6 static" >> /etc/network/interfaces
 echo "address $IP" >> /etc/network/interfaces
 echo "netmask 64" >> /etc/network/interfaces
 echo "up /sbin/ip -6 addr add dev ens3 $SUBIP6::1"
 
 CHANGEIP="n"
elif [ $INTERFACE = "4" ]
then
 IP=$(curl -s4 api.ipify.org)
 echo ""
 echo "Your ipv4 is:'$IP', do you want to change it? [y/n]"
 read CHANGEIP
fi
if [ $CHANGEIP = "y" ]
then
 echo ""
 echo "Enter the ipv4 you want to use"
 read IP
fi
if [ $CHANGEIP = "n" -o $CHANGEIP = "y" ]
then
 echo ""
 echo "Enter RPC port for node$ALIAS (Usually 221230)"
 read RPCPORT
 echo ""
 echo "Enter Port for node$ALIAS (Usually 22123)"
 read PORTD
 PORT=22123
 echo ""
 echo "Do you want to use bind feature? [y/n] (n if you don't know)"
 read BIND
 echo ""
 echo "Enter masternode private key for node $ALIAS"
 read PRIVKEY
 git clone https://github.com/Lagadsz/Transcendence-Dynamic-Chain
 mv Transcendence-Dynamic-Chain/ .transcendence_$ALIAS
  ALIAS=${ALIAS}
  CONF_DIR=~/.transcendence_$ALIAS

  # Create scripts
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
   if [ $BIND = "y" ]
then
 echo "bind=$IP" >> transcendence.conf_TEMP
fi
  echo "port=$PORTD" >> transcendence.conf_TEMP
  echo "masternodeaddr=$IP:$PORT" >> transcendence.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> transcendence.conf_TEMP
  sudo ufw allow $PORT/tcp
  sudo ufw allow $PORTD/tcp

  mv transcendence.conf_TEMP $CONF_DIR/transcendence.conf
  sh  ~/bin/transcendenced_$ALIAS.sh
  echo ""
  echo "Auto-start this masternode in system boot? (Not fully functional yet)"
  read AS
if [ $AS = "y" ]
then
 cp ~/bin/transcendenced_$ALIAS.sh /etc/init.d/transcendenced_$ALIAS.sh
 chmod +x /etc/init.d/transcendenced_$ALIAS.sh
 chmod 777 /etc/init.d/transcendenced_$ALIAS.sh
 update-rc.d transcendenced_$ALIAS.sh defaults
fi
fi
exit
