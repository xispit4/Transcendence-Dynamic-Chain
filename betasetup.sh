#/bin/bash
cd ~
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
apt-get install bc -y >/dev/null 2>&1
if [[ $(lsb_release -d) != *16.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
  exit 1
fi
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi
function getoutput() {
let CDS=0
CF=$(transcendence-cli -datadir=/root/.transcendence_$ALIAS masternode outputs | grep -A1 "$TXM" | tail -n 1 | wc -l)
while [  $CF -lt 1 ]; do
sleep 5
CF=$(transcendence-cli -datadir=/root/.transcendence_$ALIAS masternode outputs | grep -A1 "$TXM" | tail -n 1 | wc -l)
CDS=$((CDS+1))
done
if [  $CF -gt 0 ]
then
OP=$(transcendence-cli -datadir=/root/.transcendence_$ALIAS masternode outputs | grep -A1 "$TXM" | tail -n 1 -c 3)
fi
if [  $CDS -gt 3 ]
then
systemctl restart transcendenced$ALIAS
loadwallet
fi
}
function loadwallet() {
echo "Loading wallet"
let COUNTERT=0
OPN=$(transcendence-cli -datadir=/root/.transcendence_$ALIAS getblockchaininfo | wc -l)
while [  $OPN -lt 2 ]; do
sleep 10
OPN=$(transcendence-cli -datadir=/root/.transcendence_$ALIAS getblockchaininfo | wc -l)
COUNTERT=$((COUNTERT+1))
if [ $COUNTERT -gt 3 ]
then
systemctl restart transcendenced$ALIAS
fi
done
echo "Wallet loaded"
}
function configure_systemd() {
  cat << EOF > /etc/systemd/system/transcendenced$ALIAS.service
[Unit]
Description=transcendenced$ALIAS service
After=network.target
 [Service]
User=root
Group=root
 Type=forking
#PIDFile=/root/.transcendence_$ALIAS/transcendenced.pid
 ExecStart=/root/bin/transcendenced_$ALIAS.sh
ExecStop=-/root/bin/transcendence-cli_$ALIAS.sh stop
 Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
 [Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  sleep 6
  crontab -l > cron$ALIAS
  echo "@reboot systemctl start transcendenced$ALIAS" >> cron$ALIAS
  crontab cron$ALIAS
  rm cron$ALIAS
  systemctl start transcendenced$ALIAS.service
}
function configure_payment() {
  cat << EOF > /etc/systemd/system/payment$ALIAS.service
[Unit]
Description=transcendenced$ALIAS service
After=network.target
[Service]
User=root
Group=root
Type=forking
ExecStart=/bin/bash /root/bin/payment$ALIAS.sh
Restart=always
PrivateTmp=true
RestartSec=1800s
 [Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  sleep 6
  crontab -l > cron$ALIAS
  echo "@reboot systemctl start payment$ALIAS" >> cron$ALIAS
  crontab cron$ALIAS
  rm cron$ALIAS
  systemctl start payment$ALIAS.service
}
IP4=$(curl -s4 api.ipify.org)
perl -i -ne 'print if ! $a{$_}++' /etc/network/interfaces
if [ ! -d "/root/bin" ]; then
 DOSETUP="y"
else
 DOSETUP="n"
fi
clear
echo "1 - Create new nodes"
echo "2 - Remove an existing node"
echo "3 - Upgrade an existing node"
echo "4 - List aliases"
echo "5 - Return funds from VPS node"
echo "What would you like to do?"
read DO
echo ""
if [ $DO = "4" ]
then
ALIASES=$(find /root/.transcendence_* -maxdepth 0 -type d | cut -c22-)
echo -e "${GREEN}${ALIASES}${NC}"
echo ""
echo "1 - Create new nodes"
echo "2 - Remove an existing node"
echo "3 - Upgrade an existing node"
echo "4 - List aliases"
echo "5 - Return funds from VPS node"
echo "What would you like to do?"
read DO
echo ""
fi
if [ $DO = "5" ]
then
echo "Enter alias of the node to return funds"
read ALIAS
rm /root/.transcendence_$ALIAS/masternode.conf
sleep 1
systemctl stop transcendenced$ALIAS
systemctl stop payment$ALIAS
transcendence-cli -datadir=/root/.transcendence_$ALIAS stop
sleep 1
/root/bin/transcendenced_$ALIAS.sh
loadwallet
sleep 10
RAD=$(grep "sendtoaddress" bin/payment$ALIAS.sh | cut -f1 -d"$" | sed -n -e 's/^.*sendtoaddress //p')
SBAL=$(transcendence-cli -datadir=/root/.transcendence_$ALIAS getbalance | cut -f1 -d".")
echo -e "Sending ${GREEN}${SBAL}${NC} to ${GREEN}${RAD}${NC}"
transcendence-cli -datadir=/root/.transcendence_$ALIAS sendtoaddress $RAD $SBAL
fi
if [ $DO = "3" ]
then
perl -i -ne 'print if ! $a{$_}++' /etc/monit/monitrc >/dev/null 2>&1
echo "Enter the alias of the node you want to upgrade"
read ALIAS
  echo -e "Upgrading ${GREEN}${ALIAS}${NC}. Please wait."
  sed -i '/$ALIAS/d' .bashrc
  sleep 1
  ## Config Alias
  echo "alias ${ALIAS}_status=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS masternode status\"" >> .bashrc
  echo "alias ${ALIAS}_stop=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS stop && systemctl stop transcendenced$ALIAS\"" >> .bashrc
  echo "alias ${ALIAS}_start=\"/root/bin/transcendenced_${ALIAS}.sh && systemctl start transcendenced$ALIAS\""  >> .bashrc
  echo "alias ${ALIAS}_config=\"nano /root/.transcendence_${ALIAS}/transcendence.conf\""  >> .bashrc
  echo "alias ${ALIAS}_getinfo=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS getinfo\"" >> .bashrc
  configure_systemd
  sleep 1
  source .bashrc
  echo -e "${GREEN}${ALIAS}${NC} Successfully upgraded."
fi
if [ $DO = "2" ]
then
perl -i -ne 'print if ! $a{$_}++' /etc/monit/monitrc >/dev/null 2>&1
echo "Input the alias of the node that you want to delete"
read ALIAS
echo ""
echo -e "${GREEN}Deleting ${ALIAS}${NC}. Please wait."
## Removing service
systemctl stop transcendenced$ALIAS >/dev/null 2>&1
systemctl disable transcendenced$ALIAS >/dev/null 2>&1
rm /etc/systemd/system/transcendenced${ALIAS}.service >/dev/null 2>&1
systemctl stop payment$ALIAS >/dev/null 2>&1
systemctl disable payment$ALIAS >/dev/null 2>&1
rm /etc/systemd/system/payment${ALIAS}.service >/dev/null 2>&1
systemctl daemon-reload >/dev/null 2>&1
systemctl reset-failed >/dev/null 2>&1
## Stopping node
transcendence-cli -datadir=/root/.transcendence_$ALIAS stop >/dev/null 2>&1
sleep 5
## Removing monit and directory
rm /root/.transcendence_$ALIAS -r >/dev/null 2>&1
sed -i '/$ALIAS/d' .bashrc >/dev/null 2>&1
sleep 1
sed -i '/$ALIAS/d' /etc/monit/monitrc >/dev/null 2>&1
monit reload >/dev/null 2>&1
sed -i '/$ALIAS/d' /etc/monit/monitrc >/dev/null 2>&1
crontab -l -u root | grep -v transcendenced$ALIAS | crontab -u root - >/dev/null 2>&1
rm /root/bin/transcendenced_$ALIAS.sh >/dev/null 2>&1
rm /root/bin/transcendence-cli_$ALIAS.sh >/dev/null 2>&1
rm /root/bin/transcendence-tx_$ALIAS.sh >/dev/null 2>&1
rm /root/bin/payment$ALIAS.sh >/dev/null 2>&1
source .bashrc
echo -e "${ALIAS} Successfully deleted."
fi
if [ $DO = "1" ]
then
echo "1 - Easy mode"
echo "2 - Expert mode"
echo "Please select a option:"
read EE
echo ""
if [ $EE = "1" ] 
then
MAXC="32"
fi
if [ $EE = "2" ] 
then
echo ""
echo "Enter max connections value"
read MAXC
fi
if [ $DOSETUP = "y" ]
then
  echo -e "Installing ${GREEN}Transcendence dependencies${NC}. Please wait."
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
  mkdir -p ~/bin 
  echo 'export PATH=~/bin:$PATH' > ~/.bash_aliases
  source ~/.bashrc
  echo ""
fi
if [ ! -f DynamicChain.zip ]
then
wget https://github.com/Lagadsz/Transcendence-Dynamic-Chain/releases/download/v0.1/DynamicChain.zip
fi
IP4COUNT=$(find /root/.transcendence_* -maxdepth 0 -type d | wc -l)

echo -e "Telos nodes currently installed: ${GREEN}${IP4COUNT}${NC}"
echo ""
echo "How many nodes do you want to install on this server?"
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
  echo -e "Press ${GREEN}1${NC} to setup locally or ${GREEN}2${NC} to setup on the VPS"
  read LV
  if [ $LV = "1" ] 
  then
  echo ""
  echo "Enter masternode private key for node $ALIAS"
  read PRIVKEY
  if [ $EE = "2" ] 
	then
	echo ""
	echo "Enter port for $ALIAS"
	read PORTD
  fi
  mkdir ~/.transcendence_$ALIAS
  unzip DynamicChain.zip -d ~/.transcendence_$ALIAS >/dev/null 2>&1
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
  echo "maxconnections=$MAXC" >> transcendence.conf_TEMP
  echo "masternode=1" >> transcendence.conf_TEMP
  echo "dbcache=50" >> transcendence.conf_TEMP
  echo "banscore=10" >> transcendence.conf_TEMP
  echo "maxorphantx=10" >> transcendence.conf_TEMP
  echo "maxmempool=100" >> transcendence.conf_TEMP
  echo "" >> transcendence.conf_TEMP
  echo "" >> transcendence.conf_TEMP
  echo "port=$PORTD" >> transcendence.conf_TEMP
  echo "masternodeaddr=$IP4:$PORT" >> transcendence.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> transcendence.conf_TEMP
  sudo ufw allow 22123/tcp >/dev/null 2>&1
  mv transcendence.conf_TEMP $CONF_DIR/transcendence.conf
  echo ""
  echo -e "Your ip is ${GREEN}$IP4:$PORT${NC}"
  COUNTER=$((COUNTER+1))
	echo "alias ${ALIAS}_status=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS masternode status\"" >> .bashrc
	echo "alias ${ALIAS}_stop=\"systemctl stop transcendenced$ALIAS\"" >> .bashrc
	echo "alias ${ALIAS}_start=\"systemctl start transcendenced$ALIAS\""  >> .bashrc
	echo "alias ${ALIAS}_config=\"nano /root/.transcendence_${ALIAS}/transcendence.conf\""  >> .bashrc
	echo "alias ${ALIAS}_getinfo=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS getinfo\"" >> .bashrc
	echo "alias ${ALIAS}_restart=\"systemctl restart transcendenced$ALIAS\"" >> .bashrc
	echo "alias ${ALIAS}_mnsync=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS mnsync status\"" >> .bashrc
	echo "alias ${ALIAS}_reindex=\"systemctl stop transcendenced$ALIAS && sleep 5 && /root/bin/transcendenced_${ALIAS}.sh -reindex\"" >> .bashrc
	echo "alias ${ALIAS}_nodeconf=\"nano /root/.transcendence_${ALIAS}/masternode.conf\""  >> .bashrc
	echo "alias ${ALIAS}_balance=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS getbalance\""  >> .bashrc
	echo "alias ${ALIAS}_transactions=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS listtransactions\""  >> .bashrc
	## Config Systemctl
	configure_systemd
fi
if [ $LV = "2" ]
then
if [ $EE = "2" ] 
	then
	echo ""
	echo "Enter port for $ALIAS"
	read PORTD
  fi
  mkdir ~/.transcendence_$ALIAS
  unzip DynamicChain.zip -d ~/.transcendence_$ALIAS >/dev/null 2>&1
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
  echo "maxconnections=$MAXC" >> transcendence.conf_TEMP
  echo "dbcache=50" >> transcendence.conf_TEMP
  echo "banscore=10" >> transcendence.conf_TEMP
  echo "maxorphantx=10" >> transcendence.conf_TEMP
  echo "maxmempool=100" >> transcendence.conf_TEMP
  echo "" >> transcendence.conf_TEMP
  echo "" >> transcendence.conf_TEMP
  echo "port=$PORTD" >> transcendence.conf_TEMP
  sudo ufw allow 22123/tcp >/dev/null 2>&1
  mv transcendence.conf_TEMP $CONF_DIR/transcendence.conf
  echo ""
  echo -e "${GREEN}Configuring files, this may take a while.${NC}"
  COUNTER=$((COUNTER+1))
	echo "alias ${ALIAS}_status=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS masternode status\"" >> .bashrc
	echo "alias ${ALIAS}_stop=\"systemctl stop transcendenced$ALIAS\"" >> .bashrc
	echo "alias ${ALIAS}_start=\"systemctl start transcendenced$ALIAS\""  >> .bashrc
	echo "alias ${ALIAS}_config=\"nano /root/.transcendence_${ALIAS}/transcendence.conf\""  >> .bashrc
	echo "alias ${ALIAS}_getinfo=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS getinfo\"" >> .bashrc
	echo "alias ${ALIAS}_restart=\"systemctl restart transcendenced$ALIAS\"" >> .bashrc
	echo "alias ${ALIAS}_mnsync=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS mnsync status\"" >> .bashrc
	echo "alias ${ALIAS}_reindex=\"systemctl stop transcendenced$ALIAS && sleep 5 && /root/bin/transcendenced_${ALIAS}.sh -reindex\"" >> .bashrc
	echo "alias ${ALIAS}_nodeconf=\"nano /root/.transcendence_${ALIAS}/masternode.conf\""  >> .bashrc
	echo "alias ${ALIAS}_balance=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS getbalance\""  >> .bashrc
	echo "alias ${ALIAS}_transactions=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS listtransactions\""  >> .bashrc
	configure_systemd
sleep 10
echo ""
echo "Please enter receiving address to get rewards"
read READDR
loadwallet
if [  $OPN -gt 1 ]
then
VADDR=$(transcendence-cli -datadir=/root/.transcendence_$ALIAS getnewaddress Receiving)
echo -e "Please send 1001 telos to ${GREEN}${VADDR}${NC} (1 for redundancy)"
BALANCE=$(transcendence-cli -datadir=/root/.transcendence_$ALIAS getbalance | cut -f1 -d".")
UBALANCE=$(transcendence-cli -datadir=/root/.transcendence_$ALIAS getunconfirmedbalance | cut -f1 -d".")
PRIVKEY=$(transcendence-cli -datadir=/root/.transcendence_$ALIAS masternode genkey)
RCVD=0
let COUNT=0
while [  $BALANCE -lt 1000 ]; do
if [  $BALANCE -lt 1000 ]
then
sleep 10
COUNT=$((COUNT+1))
if [ $COUNT -gt 3 ]
then
systemctl restart transcendenced$ALIAS
loadwallet
fi
BALANCE=$(transcendence-cli -datadir=/root/.transcendence_$ALIAS getbalance | cut -f1 -d".")
fi
done
if [  $BALANCE -ge 1000 ]
then
echo -e "${GREEN}Transaction confirmed! Node creation started, Waiting for confirmations.${NC} "
MNA=$(transcendence-cli -datadir=/root/.transcendence_$ALIAS getnewaddress mn)
TXM=$(transcendence-cli -datadir=/root/.transcendence_$ALIAS sendtoaddress "$MNA" 1000)
getoutput
echo "mn 127.0.0.1:22123 $PRIVKEY ${TXM}${OP}" >> /root/.transcendence_$ALIAS/masternode.conf
echo "masternodeaddr=127.0.0.1:$PORT" >> /root/.transcendence_$ALIAS/transcendence.conf
echo "masternodeprivkey=$PRIVKEY" >> /root/.transcendence_$ALIAS/transcendence.conf
echo "masternode=1" >> /root/.transcendence_$ALIAS/transcendence.conf
systemctl stop transcendenced$ALIAS
sleep 10
systemctl start transcendenced$ALIAS
wget https://raw.githubusercontent.com/Lagadsz/Transcendence-Dynamic-Chain/master/paymentt -q -O /root/bin/paymentt.sh
echo "ACTI=\$(transcendence-cli -datadir=/root/.transcendence_$ALIAS masternode status | wc -l)" >> /root/bin/paymentt.sh
echo "ALIAS=$ALIAS" >> /root/bin/paymentt.sh
echo "if [ \$ACTI -lt 2 ]" >> /root/bin/paymentt.sh
echo "then" >> /root/bin/paymentt.sh
echo "systemctl restart transcendenced$ALIAS" >> /root/bin/paymentt.sh
echo "fi" >> /root/bin/paymentt.sh
echo "loadwallet" >> /root/bin/paymentt.sh
echo "BALANCE=\$(transcendence-cli -datadir=/root/.transcendence_$ALIAS getbalance | cut -f1 -d".")" >> /root/bin/paymentt.sh
echo "SBALANCE=\$(transcendence-cli -datadir=/root/.transcendence_\$ALIAS listunspent | grep "amount" | cut -f1 -d"." | sed -e 's/[^0-9 ]//g' | sed -e 's/^ *//' | sed -e 's/ *$// ' | paste -sd+ | bc)" >> /root/bin/paymentt.sh
echo "transcendence-cli -datadir=/root/.transcendence_$ALIAS sendtoaddress $READDR \$SBALANCE" >> /root/bin/paymentt.sh
mv /root/bin/paymentt.sh /root/bin/payment$ALIAS.sh 
chmod 777 /root/bin/payment$ALIAS.sh 
configure_payment
fi
fi
fi
done
echo ""
echo "Commands:"
echo "ALIAS_start"
echo "ALIAS_status"
echo "ALIAS_stop"
echo "ALIAS_config"
echo "ALIAS_getinfo"
echo "ALIAS_restart"
echo "ALIAS_mnsync"
echo "ALIAS_reindex"
echo "ALIAS_nodeconf"
echo "ALIAS_balance"
echo "ALIAS_transactions"
fi
echo ""
echo "Made by lobo with the help of all Transcendence team "
echo "Transcendence Address for donations: GWe4v6A6tLg9pHYEN5MoAsYLTadtefd9o6"
echo "Bitcoin Address for donations: 1NqYjVMA5DhuLytt33HYgP5qBajeHLYn4d"
exec bash
exit
