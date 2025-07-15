#!/bin/sh

while :
do
	DATE=$(date)
	eval /opt/zap2xml.pl "$OPT_ARGS"
	echo "Last run time: $DATE"
	echo "Will run in $SLEEPTIME seconds"
	sleep "$SLEEPTIME"
done
