#/bin/bash
echo ""
echo "Input the alias of the node that you want to delete"
read ALIAS
transcendence-cli -datadir=/root/.transcendence_$ALIAS stop
rm /root/.transcendence_$ALIAS -r
sed -i '/$ALIAS/d' .bashrc
sleep 5
sed -i '/$ALIAS/d' /etc/monit/monitrc
monit reload
echo ""
echo "You can ignore any errors that appear after this script"
exec bash
done
