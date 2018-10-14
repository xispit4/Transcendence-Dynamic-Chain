#/bin/bash
cd ~
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
user=$(whoami)
function configure_systemd() {
 sudo bash -c 'cat << EOF > /etc/systemd/system/transcendence.service
[Unit]
Description=transcendence service
After=network.target
[Service]
User=$user
Group=$user
Type=forking
Environment="DISPLAY=:0"
Environment="XAUTHORITY=/home/$user/.Xauthority"
#PIDFile=/home/$user/.transcendence/transcendenced.pid
ExecStart=/home/$user/bin/transcendence-qt.sh
ExecStop=/home/$user/bin/transcendence-cli.sh stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=graphical.target
EOF'
  sudo systemctl daemon-reload
  sleep 6
  sudo crontab -l > cron
  sudo echo "@reboot systemctl start transcendence" >> cron
  sudo crontab cron
  sudo rm cron
  sudo systemctl start transcendence.service
}
if [ ! -d "/home/$user/bin" ]; then
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
sudo systemctl stop transcendence >/dev/null 2>&1
sudo systemctl disable transcendence >/dev/null 2>&1
sudo rm /etc/systemd/system/transcendence.service >/dev/null 2>&1
sudo systemctl daemon-reload >/dev/null 2>&1
sudo systemctl reset-failed >/dev/null 2>&1
transcendence-cli -datadir=/home/$user/.transcendence stop >/dev/null 2>&1
sleep 5
sudo rm /home/$user/.transcendence -r >/dev/null 2>&1
sudo rm /home/$user/bin/* >/dev/null 2>&1
sudo crontab -l -u $user | grep -v transcendence | crontab -u $user - >/dev/null 2>&1
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
  sudo apt-get install -y zip unzip curl nano screen
  cd /var
  sudo touch swap.img
  sudo chmod 600 swap.img
  sudo dd if=/dev/zero of=/var/swap.img bs=1024k count=$SWP
  sudo mkswap /var/swap.img 
  sudo swapon /var/swap.img 
  sudo free 
  sudo echo "/var/swap.img none swap sw 0 0" >> /etc/fstab
  cd
 if [ ! -f /usr/local/bin/transcendence-qt ]
  then
  https://github.com/phoenixkonsole/transcendence/releases/download/v1.1.0.0/1533585445_Transcendence_ARMhf.zip 
  mkdir Linux
  mkdir Linux/bin
  unzip 1533585445_Transcendence_ARMhf.zip -d Linux/bin
  chmod +x Linux/bin/* 
  sudo mv  Linux/bin/* /usr/local/bin
  rm -rf Linux.zip Windows Linux Mac
 fi
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
  echo '#!/bin/bash' > ~/bin/transcendenced.sh
  echo "transcendenced -daemon -conf=$CONF_DIR/transcendence.conf -datadir=$CONF_DIR "'$*' >> ~/bin/transcendenced.sh
  echo '#!/bin/bash' > ~/bin/transcendence-cli.sh
  echo "transcendence-cli -conf=$CONF_DIR/transcendence.conf -datadir=$CONF_DIR "'$*' >> ~/bin/transcendence-cli.sh
  echo '#!/bin/bash' > ~/bin/transcendence-tx.sh
  echo "transcendence-tx -conf=$CONF_DIR/transcendence.conf -datadir=$CONF_DIR "'$*' >> ~/bin/transcendence-tx.sh
  echo '#!/bin/bash' > ~/bin/transcendence-qt.sh
  echo "screen -d -m transcendence-qt -conf=$CONF_DIR/transcendence.conf -datadir=$CONF_DIR "'$*' >> ~/bin/transcendence-qt.sh
  sudo chmod 755 ~/bin/transcendence*.sh
  sudo rm ~/.transcendence/transcendence.conf
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
	echo "alias telos_stop=\"sudo systemctl stop transcendence\"" >> .bashrc
	echo "alias telos_start=\"sudo systemctl start transcendence\""  >> .bashrc
	echo "alias telos_config=\"nano /home/$user/.transcendence/transcendence.conf\""  >> .bashrc
	echo "alias telos_getinfo=\"transcendence-cli -datadir=/home/$user/.transcendence getinfo\"" >> .bashrc
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
