#!/bin/sh

SLEEP_TIME=${SLEEP_TIME:-10800}

while true; do
    DATE=$(date)
    node dist/index.js
    echo "Last run time: $DATE"
    echo "Will run in $((SLEEP_TIME / 60)) minutes"
    sleep "$SLEEP_TIME"
done
