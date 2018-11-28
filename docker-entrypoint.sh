#!/bin/bash
set -e

# Change JVM config to set max heap size to 512m instead of default
sed -i "s/-Xms.*\w/-Xms${HUB_LOGSTASH_MAX_MEMORY:-512m}/g" /usr/share/logstash/config/jvm.options
sed -i "s/-Xmx.*\w/-Xmx${HUB_LOGSTASH_MAX_MEMORY:-640m}/g" /usr/share/logstash/config/jvm.options


# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- logstash "$@"
fi

# Run as user "logstash" if the command is "logstash"
# allow the container to be started with `--user`
if  [ "$1" = 'logstash' ] && [ "$(id -u)" = '0' ]; then
	# Existing files and directories should be accessible by 'others'
	find /var/lib/logstash/data -mindepth 1 -type d -exec chmod 775 {} \;
	find /var/lib/logstash/data -type f -exec chmod 664 {} \;

	set -- su-exec logstash:root "$@"
fi

# TODO: webapp also writes to this volume, so a general chmod fails.
# If we do start as the logstash user (uid 100) update the permissions so
# that files and directories are writable by the root group.
# Previous versions did not have this quite right.
#if [ "$(id -u)" = '100' ]; then
#	# 'chmod' will fail if the directory is empty. Need to check first.
#	if [ -z "$(ls -A /var/lib/logstash/data)" ]; then
#		echo "No logs have been written yet, not updating permissions."
#	else
#		echo "Some logs exist already, updating permissions."
#		pushd /var/lib/logstash/data
#		chmod -R g+w *
#		popd
#	fi
#fi

if [ "${HUB_LOGSTASH_ES_ENABLE}" = 'true' ]; then
    sed -i "s/#elasticsearch/elasticsearch/g" /usr/share/logstash/pipeline/logstash.conf
fi

/usr/local/bin/deleteLogs.sh &

if [[ -z $1 ]] || [[ ${1:0:1} == '-' ]] ; then
  exec logstash "$@"
else
  exec "$@"
fi
