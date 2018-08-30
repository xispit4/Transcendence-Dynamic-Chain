#/bin/bash
echo ""
echo "Input the alias of the node that you want to delete"
read ALIAS
transcendence-cli -datadir=/root/.transcendence_$ALIAS stop
rm /root/.transcendence_$ALIAS -r
sed -i '/$ALIAS/d' .bashrc
sed -i '/$ALIAS/d' /etc/monit/monitrc
monit reload
exec bash
done
