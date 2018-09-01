#/bin/bash
perl -i -ne 'print if ! $a{$_}++' /etc/monit/monitrc
echo "Enter the alias of the node you want to upgrade"
read ALIAS
echo ""
echo "Do you already have a upgraded node in this server? [y/n]"
read UP
if [ $UP = "n" ]
then
	apt-get install monit=1:5.16-2 -y
	wget https://raw.githubusercontent.com/Lagadsz/Transcendence-Dynamic-Chain/master/monitrc
	rm /etc/monit/monitrc
	cp -a monitrc /etc/monit/monitrc
	chmod 700 /etc/monit/monitrc
fi
  ## Config Alias
  echo "alias ${ALIAS}_status=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS masternode status\"" >> .bashrc
  echo "alias ${ALIAS}_stop=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS stop && monit stop transcendenced${ALIAS} && rm ~/.transcendence_${ALIAS}/transcendenced${ALIAS}.pid\"" >> .bashrc
  echo "alias ${ALIAS}_start=\"/root/bin/transcendenced_${ALIAS}.sh && sleep 1 && mv ~/.transcendence_${ALIAS}/transcendenced.pid ~/.transcendence_${ALIAS}/transcendenced${ALIAS}.pid && monit start transcendenced${ALIAS}\""  >> .bashrc
  echo "alias ${ALIAS}_config=\"nano /root/.transcendence_${ALIAS}/transcendence.conf\""  >> .bashrc
  echo "alias ${ALIAS}_getinfo=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS getinfo\"" >> .bashrc
  ## Config Monit
  echo "check process transcendenced${ALIAS} with pidfile /root/.transcendence_${ALIAS}/transcendenced${ALIAS}.pid" >> /etc/monit/monitrc
  echo "start program = \"/root/bin/transcendenced_${ALIAS}.sh\" with timeout 60 seconds" >> /etc/monit/monitrc
  echo "stop program = \"/root/bin/transcendenced_${ALIAS}.sh stop\"" >> /etc/monit/monitrc
  transcendence-cli -datadir=/root/.transcendence_$ALIAS stop
  perl -i -ne 'print if ! $a{$_}++' /etc/monit/monitrc
  sleep 1
  monit reload
  sleep 1
  /root/bin/transcendenced_${ALIAS}.sh
  sleep 4
  mv ~/.transcendence_${ALIAS}/transcendenced.pid ~/.transcendence_${ALIAS}/transcendenced${ALIAS}.pid 
  monit 
  sleep 2
  monit start transcendenced${ALIAS}
  echo ""
  echo "Reboot is recommended after upgrading all your nodes, tho not necessary"
  exec bash
  exit
