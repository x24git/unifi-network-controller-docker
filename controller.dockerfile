FROM debian:bookworm-slim

ARG BUILD_DATE \
    UNIFI_VERSION \
    UNIFI_BRANCH="stable" \
    UNIFI_GID="999" \
    UNIFI_UID="999" 

LABEL maintainer="x24git"

# environment settings
ENV DEBIAN_FRONTEND="noninteractive"
ENV UNIFI_HOOK_LOGS="/unifi/logs/server.log|/unifi/logs/startup.log"

COPY ./controller/tmp /tmp/
COPY ./controller/etc /etc/

RUN chmod +x /tmp/scripts/* && chmod -R +xr /etc/unifi/
# Execute each script during the build
RUN set -ex && \
    for script in /tmp/scripts/*; do \
    if [ -f "$script" ]; then \
    echo "Executing $script"; \
    "$script"; \
    if [ $? -ne 0 ]; then\
    echo "Script $script failed, exiting loop.";\
    exit 1;\
    fi\
    fi\
    done && \
    rm -rf /tmp/scripts 

LABEL build_version="Unifi Network Application:- ${UNIFI_VERSION} Build-date:- ${BUILD_DATE}"
VOLUME /unifi

COPY entrypoint.sh /usr/local/bin
RUN chmod 744 /usr/local/bin/entrypoint.sh


USER unifi
WORKDIR /usr/lib/unifi
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
