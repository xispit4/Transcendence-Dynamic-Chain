#/bin/bash
perl -i -ne 'print if ! $a{$_}++' /etc/monit/monitrc
echo ""
echo "Input the alias of the node that you want to delete"
read ALIAS
transcendence-cli -datadir=/root/.transcendence_$ALIAS stop
sleep 5
rm /root/.transcendence_$ALIAS -r
sed -i '/$ALIAS/d' /etc/monit/monitrc
sleep 5
sed -i '/$ALIAS/d' .bashrc
perl -i -ne 'print if ! $a{$_}++' /etc/monit/monitrc
monit reload
echo ""
echo "You can ignore any errors that appear after this script"
exec bash
done
