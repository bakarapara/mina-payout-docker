#!/bin/bash -x

STATUS=1
while [ $STATUS != 0 ]
do
	psql -U archive -d archive -c "select count(*) from blocks"
	STATUS=$?
	sleep 5
done

while [ 1 == 1 ]
do
	coda-archive run -postgres-uri "postgresql://archive:archive@127.0.0.1/archive" -server-port 3086
	echo "Crashed..."
done
