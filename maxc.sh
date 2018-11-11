#/bin/bash
echo ""
echo "Enter maxc value"
read maxc
while true
do
echo ""
echo "Enter alias to change maxc"
read alias
sed -i '/maxconnections/d' /root/.transcendence_$alias/transcendence.conf
echo "maxconnections=$maxc" >> /root/.transcendence_$alias/transcendence.conf
done
