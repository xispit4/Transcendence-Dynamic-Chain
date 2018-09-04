#/bin/bash
perl -i -ne 'print if ! $a{$_}++' /etc/monit/monitrc
echo "Enter the alias of the node you want to upgrade"
read ALIAS
  sed -i '/$ALIAS/d' .bashrc
  sleep 1
  ## Config Alias
  echo "alias ${ALIAS}_status=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS masternode status\"" >> .bashrc
  echo "alias ${ALIAS}_stop=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS stop && systemctl stop transcendenced$ALIAS\"" >> .bashrc
  echo "alias ${ALIAS}_start=\"/root/bin/transcendenced_${ALIAS}.sh && systemctl start transcendenced$ALIAS\""  >> .bashrc
  echo "alias ${ALIAS}_config=\"nano /root/.transcendence_${ALIAS}/transcendence.conf\""  >> .bashrc
  echo "alias ${ALIAS}_getinfo=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS getinfo\"" >> .bashrc
  ## Config systemd
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
  sleep 3
  systemctl start transcendenced$ALIAS.service
}
  configure_systemd
  sleep 1
  exec bash
  exit
