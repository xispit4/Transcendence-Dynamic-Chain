#/bin/bash
perl -i -ne 'print if ! $a{$_}++' /etc/monit/monitrc 
echo ""
echo "Input the alias of the node that you want to delete"
read ALIAS
## Removing service
systemctl stop transcendenced$ALIAS
systemctl disable transcendenced$ALIAS
rm /etc/systemd/system/transcendenced${ALIAS}.service
systemctl daemon-reload
systemctl reset-failed
## Stopping node
transcendence-cli -datadir=/root/.transcendence_$ALIAS stop
sleep 5
## Removing monit and directory
rm /root/.transcendence_$ALIAS -r
sed -i '/$ALIAS/d' /etc/monit/monitrc
sed -i '/$ALIAS/d' .bashrc
sleep 5
perl -i -ne 'print if ! $a{$_}++' /etc/monit/monitrc
monit reload
echo ""
echo "You can ignore any errors that appear during/after this script"
exec bash
done
