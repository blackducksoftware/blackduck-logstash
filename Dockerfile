FROM blackducksoftware/hub-docker-common:1.0.1 as docker-common
FROM docker.elastic.co/logstash/logstash:5.6.8

ARG VERSION
ARG LASTCOMMIT
ARG BUILDTIME
ARG BUILD

LABEL com.blackducksoftware.hub.vendor="Black Duck Software, Inc." \
      com.blackducksoftware.hub.version="$VERSION" \
      com.blackducksoftware.hub.lastCommit="$LASTCOMMIT" \
      com.blackducksoftware.hub.buildTime="$BUILDTIME" \
      com.blackducksoftware.hub.build="$BUILD"

# Reset to root from base image.
USER root

ENV BLACKDUCK_RELEASE_INFO "com.blackducksoftware.hub.vendor=Black Duck Software, Inc. \
com.blackducksoftware.hub.version=$VERSION \
com.blackducksoftware.hub.lastCommit=$LASTCOMMIT \
com.blackducksoftware.hub.buildTime=$BUILDTIME \
com.blackducksoftware.hub.build=$BUILD"

ENV HUB_LOGSTASH_ES_ENABLE "false"

RUN echo -e "$BLACKDUCK_RELEASE_INFO" > /etc/blackduckrelease

COPY logstash-hub.conf "/usr/share/logstash/pipeline/logstash.conf"
COPY patterns "/usr/share/logstash/pipeline/patterns/"
COPY logstash-hub.yml "/usr/share/logstash/config/logstash.yml"
COPY --from=docker-common healthcheck.sh /usr/local/bin/docker-healthcheck.sh
COPY docker-entrypoint.sh /usr/local/bin/

RUN set -e \
    # Older versions of hub-logstash were based on Alpine
    # Alpine used the UID 100 for the logstash user
    # To avoid permission issues in the short-term, change the logtash user
    # here to also be 100.
    # The 'games' user is by default 100. We have no need to that user, so remove it first.
    && userdel -f games \
    && usermod -u 100 logstash \
    && rm "/usr/local/bin/docker-entrypoint" \
    && mkdir -p "/var/lib/logstash/data" "/var/lib/logstash/config" "/usr/share/logstash/config" "/usr/share/logstash/data" \
    && chown logstash:root "/var/lib/logstash" \
    && chown -R logstash:root "/var/lib/logstash/config" "/usr/share/logstash" \
    && chmod 775 /usr/local/bin/docker-entrypoint.sh "/var/lib/logstash/data" "/var/lib/logstash/config" "/usr/share/logstash/config" "/usr/share/logstash/data"

# copy delete log script
RUN touch /var/log/deleteLogs.log
RUN chmod 0666 /var/log/deleteLogs.log
ADD deleteLogs.sh /usr/local/bin/deleteLogs.sh
RUN chmod 0755 /usr/local/bin/deleteLogs.sh

EXPOSE 4560

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
