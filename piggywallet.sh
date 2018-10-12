#/bin/bash
cd ~
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi
function configure_systemd() {
  cat << EOF > /etc/systemd/system/transcendence.service
[Unit]
Description=transcendence service
After=network.target
[Service]
User=orangepi
Group=orangepi
Type=forking
Environment="DISPLAY=:0"
Environment="XAUTHORITY=/home/orangepi/.Xauthority"
#PIDFile=/home/orangepi/.transcendence/transcendenced.pid
ExecStart=/usr/bin/screen -d -m /home/orangepi/bin/transcendence-qt.sh
ExecStop=/home/orangepi/bin/transcendence-cli.sh stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=graphical.target
EOF
  systemctl daemon-reload
  sleep 6
  crontab -l > cron
  echo "@reboot systemctl start transcendence" >> cron
  crontab cron
  rm cron
  systemctl start transcendence.service
}
if [ ! -d "/home/orangepi/bin" ]; then
 DOSETUP="y"
else
 DOSETUP="n"
fi
clear
echo "1 - Create wallet"
echo "2 - Delete wallet"
echo "What would you like to do?"
read DO
echo ""
if [ $DO = "2" ]
then
echo -e "${GREEN}Deleting wallet${NC}. Please wait."
systemctl stop transcendence >/dev/null 2>&1
systemctl disable transcendence >/dev/null 2>&1
rm /etc/systemd/system/transcendence.service >/dev/null 2>&1
systemctl daemon-reload >/dev/null 2>&1
systemctl reset-failed >/dev/null 2>&1
transcendence-cli -datadir=/home/orangepi/.transcendence stop >/dev/null 2>&1
sleep 5
rm /home/orangepi/.transcendence -r >/dev/null 2>&1
rm /home/orangepi/bin/* >/dev/null 2>&1
crontab -l -u orangepi | grep -v transcendence | crontab -u orangepi - >/dev/null 2>&1
source .bashrc
echo -e "Wallet Successfully deleted."
fi
if [ $DO = "1" ]
then
echo "1 - Easy mode"
echo "2 - Expert mode (Change port, Swap and Max Connections(Default 32))"
echo "Please select a option:"
read EE
echo ""
if [ $EE = "1" ] 
then
MAXC="32"
SWP="2000"
fi
if [ $EE = "2" ] 
then
echo ""
echo "Enter max connections value"
read MAXC
echo ""
echo "Enter swap size in mb"
read SWP
fi
if [ $DOSETUP = "y" ]
then
  echo -e "Installing ${GREEN}Transcendence dependencies${NC}. Please wait."
  sudo apt-get update 
  sudo apt-get -y upgrade
  sudo apt-get -y dist-upgrade
  sudo apt-get update
  sudo apt-get install -y zip unzip curl nano
  cd /var
  sudo touch swap.img
  sudo chmod 600 swap.img
  sudo dd if=/dev/zero of=/var/swap.img bs=1024k count=$SWP
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
 PORT=22123
 RPCPORT=$(($PORT*10))
  CONF_DIR=~/.transcendence
  if [ $EE = "2" ] 
	then
	echo ""
	echo "Enter port for wallet"
	read PORTD
  fi
  mkdir ~/.transcendence
  unzip DynamicChain.zip -d ~/.transcendence >/dev/null 2>&1
  echo '#!/bin/bash' > ~/bin/transcendenced.sh
  echo "transcendenced -daemon -conf=$CONF_DIR/transcendence.conf -datadir=$CONF_DIR "'$*' >> ~/bin/transcendenced.sh
  echo '#!/bin/bash' > ~/bin/transcendence-cli.sh
  echo "transcendence-cli -conf=$CONF_DIR/transcendence.conf -datadir=$CONF_DIR "'$*' >> ~/bin/transcendence-cli.sh
  echo '#!/bin/bash' > ~/bin/transcendence-tx.sh
  echo "transcendence-tx -conf=$CONF_DIR/transcendence.conf -datadir=$CONF_DIR "'$*' >> ~/bin/transcendence-tx.sh
  echo '#!/bin/bash' > ~/bin/transcendence-qt.sh
  echo "transcendence-qt -conf=$CONF_DIR/transcendence.conf -datadir=$CONF_DIR "'$*' >> ~/bin/transcendence-qt.sh
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
  echo "maxorphantx=10" >> transcendence.conf_TEMP
  echo "maxmempool=100" >> transcendence.conf_TEMP
  echo "banscore=10" >> transcendence.conf_TEMP
  echo "" >> transcendence.conf_TEMP
  echo "" >> transcendence.conf_TEMP
  echo "port=$PORT" >> transcendence.conf_TEMP
  sudo ufw allow 22123/tcp
  mv transcendence.conf_TEMP $CONF_DIR/transcendence.conf
  echo ""
  COUNTER=$((COUNTER+1))
	echo "alias telos_stop=\"systemctl stop transcendence\"" >> .bashrc
	echo "alias telos_start=\"systemctl start transcendence\""  >> .bashrc
	echo "alias telos_config=\"nano /home/orangepi/.transcendence/transcendence.conf\""  >> .bashrc
	echo "alias telos_getinfo=\"transcendence-cli -datadir=/home/orangepi/.transcendence getinfo\"" >> .bashrc
	## Config Systemctl
	configure_systemd
echo ""
echo "Commands:"
echo "telos_start"
echo "telos_stop"
echo "telos_config"
echo "telos_getinfo"
fi
echo ""
echo "Made by lobo with the help of all Transcendence team "
echo "Transcendence Address for donations: GWe4v6A6tLg9pHYEN5MoAsYLTadtefd9o6"
echo "Bitcoin Address for donations: 1NqYjVMA5DhuLytt33HYgP5qBajeHLYn4d"
exec bash
exit
