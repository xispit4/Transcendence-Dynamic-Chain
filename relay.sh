#/bin/bash
while [ 1 = 1 ]
do
monit reload
sleep 1
monit stop all
sleep 2
monit start all
sleep 10000
done
