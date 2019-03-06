#!/bin/sh

while true; do
NUM_DAYS=${DAYS_TO_KEEP_LOGS:-14}
echo "Files deleted on $(date +%x_%r):" >> /var/log/deleteLogs.log
find /var/lib/logstash/data/ -mindepth 2 -type f -mtime +$NUM_DAYS >> /var/log/deleteLogs.log
find /var/lib/logstash/data/ -mindepth 2 -type f -mtime +$NUM_DAYS -delete
sleep 1d
done
