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
echo "!    THIS SCRIPT MUST BE RUN AS ROOT, NOT SUDO    !"
echo "!                                                 !"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo && echo && echo

perl -i -ne 'print if ! $a{$_}++' /etc/monit/monitrc

echo "Is this your first time using this script? [y/n]"
read DOSETUP
echo ""
echo "What interface do you want to use? (4 For ipv4 or 6 for ipv6) (Automatic ipv6 optimized for vultr)"
read INTERFACE
echo ""
echo ""
echo "Do you want to install monit? (Automatically restarts node if it crashes) [y/n]"
read MONIT
IP4=$(curl -s4 api.ipify.org)
IP6=$(curl v6.ipv6-test.com/api/myip.php)

cd
if [ ! -f DynamicChain.zip ]
then
wget https://github.com/Lagadsz/Transcendence-Dynamic-Chain/releases/download/v0.1/DynamicChain.zip
fi
if [ $DOSETUP = "y" ]
then
if [ $INTERFACE = "6" ]
then
  face="$(lshw -C network | grep "logical name:" | sed -e 's/logical name:/logical name: /g' | awk '{print $3}')"
  echo "iface $face inet6 static" >> /etc/network/interfaces
  echo "address $IP6" >> /etc/network/interfaces
  echo "netmask 64" >> /etc/network/interfaces
fi
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
  
 if [ ! -f Linux.zip ]
  then
  wget https://github.com/phoenixkonsole/transcendence/releases/download/v1.1.0.0/Linux.zip
 fi
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
## Setup Monit
if [ $MONIT = "y" ]
	then
	if [ ! -f /etc/monit/monitrc ]
then
	echo ""
    echo "Monit not found, installing it"
	apt-get install monit=1:5.16-2 -y
	wget https://raw.githubusercontent.com/Lagadsz/Transcendence-Dynamic-Chain/master/monitrc
	rm /etc/monit/monitrc
	cp -a monitrc /etc/monit/monitrc
	chmod 700 /etc/monit/monitrc
fi
  fi


 ## Setup conf 
if [ $INTERFACE = "4" ]
then
echo ""
echo "How many ipv4 nodes do you already have on this server? (0 if none)"
read IP4COUNT
echo ""
echo "How many nodes do you want to create on this server? [min:1 Max:20]  followed by [ENTER]:"
read MNCOUNT
let COUNTER=0
let MNCOUNT=MNCOUNT+IP4COUNT
let COUNTER=COUNTER+IP4COUNT
while [  $COUNTER -lt $MNCOUNT ]; do
 PORT=22123
 PORTD=$((22123+$COUNTER))
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
  echo "maxconnections=32" >> transcendence.conf_TEMP
  echo "masternode=1" >> transcendence.conf_TEMP
  echo "dbcache=50" >> transcendence.conf_TEMP
  echo "banscore=10" >> transcendence.conf_TEMP
  echo "" >> transcendence.conf_TEMP

  echo "" >> transcendence.conf_TEMP
  echo "port=$PORTD" >> transcendence.conf_TEMP
  echo "masternodeaddr=$IP4:$PORT" >> transcendence.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> transcendence.conf_TEMP
  sudo ufw allow $PORT/tcp
  mv transcendence.conf_TEMP $CONF_DIR/transcendence.conf 
  echo "Your ip is $IP4:$PORTD"
  COUNTER=$((COUNTER+1))
  if [ $MONIT = "y" ]
	then
	echo "alias ${ALIAS}_status=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS masternode status\"" >> .bashrc
	echo "alias ${ALIAS}_stop=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS stop && monit stop transcendenced${ALIAS} && rm ~/.transcendence_${ALIAS}/transcendenced${ALIAS}.pid\"" >> .bashrc
	echo "alias ${ALIAS}_start=\"/root/bin/transcendenced_${ALIAS}.sh && sleep 1 && mv ~/.transcendence_${ALIAS}/transcendenced.pid ~/.transcendence_${ALIAS}/transcendenced${ALIAS}.pid && monit start transcendenced${ALIAS}\""  >> .bashrc
	echo "alias ${ALIAS}_config=\"nano /root/.transcendence_${ALIAS}/transcendence.conf\""  >> .bashrc
	echo "alias ${ALIAS}_getinfo=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS getinfo\"" >> .bashrc
	## Config Monit
	echo "check process transcendenced${ALIAS} with pidfile /root/.transcendence_${ALIAS}/transcendenced${ALIAS}.pid" >> /etc/monit/monitrc
	echo "start program = \"/root/bin/transcendenced_${ALIAS}.sh\" with timeout 60 seconds" >> /etc/monit/monitrc
	echo "stop program = \"/root/bin/transcendenced_${ALIAS}.sh stop\"" >> /etc/monit/monitrc
	/root/bin/transcendenced_${ALIAS}.sh
	perl -i -ne 'print if ! $a{$_}++' /etc/monit/monitrc
	monit reload
	sleep 1
	monit
	sleep 1 
	mv ~/.transcendence_${ALIAS}/transcendenced.pid ~/.transcendence_${ALIAS}/transcendenced${ALIAS}.pid
	monit start transcendenced${ALIAS}
  fi
  if [ $MONIT = "n" ]
	then
	echo "alias ${ALIAS}_status=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS masternode status\"" >> .bashrc
	echo "alias ${ALIAS}_stop=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS stop\"" >> .bashrc
	echo "alias ${ALIAS}_start=\"/root/bin/transcendenced_${ALIAS}.sh\""  >> .bashrc
	echo "alias ${ALIAS}_config=\"nano /root/.transcendence_${ALIAS}/transcendence.conf\""  >> .bashrc
	echo "alias ${ALIAS}_getinfo=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS getinfo\"" >> .bashrc
	/root/bin/transcendenced_${ALIAS}.sh
  fi
  
done
fi

if [ $INTERFACE = "6" ]
then
face="$(lshw -C network | grep "logical name:" | sed -e 's/logical name:/logical name: /g' | awk '{print $3}')"
gateway1=$(/sbin/route -A inet6 | grep -w "$face")
gateway2=${gateway1:0:26}
gateway3="$(echo -e "${gateway2}" | tr -d '[:space:]')"
if [[ $gateway3 = *"128"* ]]; then
  gateway=${gateway3::-5}
fi
if [[ $gateway3 = *"64"* ]]; then
  gateway=${gateway3::-3}
fi
echo ""
echo "How many ipv6 nodes do you already have on this server? (0 if none)"
read IP6COUNT
echo ""
echo "How many nodes do you want to create on this server?"
read MNCOUNT
let MNCOUNT=MNCOUNT+1
let MNCOUNT=MNCOUNT+IP6COUNT
let COUNTER=1
let COUNTER=COUNTER+IP6COUNT

 while [  $COUNTER -lt $MNCOUNT ]; do
 echo "up /sbin/ip -6 addr add dev ens3 ${gateway}$COUNTER" >> /etc/network/interfaces
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
  echo "dbcache=50" >> transcendence.conf_TEMP
  echo "banscore=10" >> transcendence.conf_TEMP
  echo "" >> transcendence.conf_TEMP

  echo "" >> transcendence.conf_TEMP
  echo "bind=[${gateway}$COUNTER]" >> transcendence.conf_TEMP
  echo "port=$PORT" >> transcendence.conf_TEMP
  echo "masternodeaddr=[${gateway}$COUNTER]:$PORT" >> transcendence.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> transcendence.conf_TEMP
  sudo ufw allow $PORT/tcp
  mv transcendence.conf_TEMP $CONF_DIR/transcendence.conf
  systemctl restart networking.service
  sleep 1
  mv ~/.transcendence_${ALIAS}/transcendenced.pid ~/.transcendence_${ALIAS}/transcendenced${ALIAS}.pid
  echo "Your ip is [${gateway}$COUNTER]"
  COUNTER=$((COUNTER+1))
  if [ $MONIT = "y" ]
	then
	echo "alias ${ALIAS}_status=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS masternode status\"" >> .bashrc
	echo "alias ${ALIAS}_stop=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS stop && monit stop transcendenced${ALIAS} && rm ~/.transcendence_${ALIAS}/transcendenced${ALIAS}.pid\"" >> .bashrc
	echo "alias ${ALIAS}_start=\"/root/bin/transcendenced_${ALIAS}.sh && sleep 1 && mv ~/.transcendence_${ALIAS}/transcendenced.pid ~/.transcendence_${ALIAS}/transcendenced${ALIAS}.pid && monit start transcendenced${ALIAS}\""  >> .bashrc
	echo "alias ${ALIAS}_config=\"nano /root/.transcendence_${ALIAS}/transcendence.conf\""  >> .bashrc
	echo "alias ${ALIAS}_getinfo=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS getinfo\"" >> .bashrc
	## Config Monit
	echo "check process transcendenced${ALIAS} with pidfile /root/.transcendence_${ALIAS}/transcendenced${ALIAS}.pid" >> /etc/monit/monitrc
	echo "start program = \"/root/bin/transcendenced_${ALIAS}.sh\" with timeout 60 seconds" >> /etc/monit/monitrc
	echo "stop program = \"/root/bin/transcendenced_${ALIAS}.sh stop\"" >> /etc/monit/monitrc
	/root/bin/transcendenced_${ALIAS}.sh
	perl -i -ne 'print if ! $a{$_}++' /etc/monit/monitrc
	monit reload
	sleep 1
	monit
	sleep 1 
	mv ~/.transcendence_${ALIAS}/transcendenced.pid ~/.transcendence_${ALIAS}/transcendenced${ALIAS}.pid
	monit start transcendenced${ALIAS}
  fi
  if [ $MONIT = "n" ]
	then
	echo "alias ${ALIAS}_status=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS masternode status\"" >> .bashrc
	echo "alias ${ALIAS}_stop=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS stop\"" >> .bashrc
	echo "alias ${ALIAS}_start=\"/root/bin/transcendenced_${ALIAS}.sh\""  >> .bashrc
	echo "alias ${ALIAS}_config=\"nano /root/.transcendence_${ALIAS}/transcendence.conf\""  >> .bashrc
	echo "alias ${ALIAS}_getinfo=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS getinfo\"" >> .bashrc
	/root/bin/transcendenced_${ALIAS}.sh
  fi
done
fi

if [ ! -f delete.sh ]
then
wget https://raw.githubusercontent.com/Lagadsz/Transcendence-Dynamic-Chain/master/delete.sh
fi
chmod 777 delete.sh
## Final echos
echo ""
echo "Made by lobo and g0dz0r"
echo "Transcendence Address for donations: GWe4v6A6tLg9pHYEN5MoAsYLTadtefd9o6"
echo ""
echo "To delete a node for reinstalling or just removing it, use delete script using ./delete.sh"
echo ""
echo "Commands:"
echo "ALIAS_start"
echo "ALIAS_status"
echo "ALIAS_stop"
echo "ALIAS_config"
echo "ALIAS_getinfo"
perl -i -ne 'print if ! $a{$_}++' /etc/monit/monitrc
exec bash
exit
