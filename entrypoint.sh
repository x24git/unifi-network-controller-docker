#!/bin/bash

set -e
if [[ -z ${MEM_LIMIT} ]] || [[ ${MEM_LIMIT} = "default" ]]; then
    MEM_LIMIT="1024";
fi
if [ "$(id unifi -u)" != "${PUID}" ] || [ "$(id unifi -g)" != "${PGID}" ]; then
    echo "ERROR: Changing you cannot change 'unifi' UID to '${PUID}' and/or GID to '${PGID}' at runtime.\n REBUILD CONTAINER TO REASSIGN UID/GUI";
    exit 1;
fi


SCRIPTS_DIR="/etc/unifi/scripts" 
for script in "$SCRIPTS_DIR"/*; do
    if grep -q '# longrun=true' "$script"; then
        echo "Running $(basename "$script") in the background..."
        bash -e -p "$script" &  # Run in the background
    else
        echo "Running $(basename "$script")..."
        bash -e -p "$script"    # Run in the foreground
    fi
done

echo "Starting UNIFI Controller"
java \
    -Xmx"${MEM_LIMIT}M" \
    -Dlog4j2.formatMsgNoLookups=true \
    -Dfile.encoding=UTF-8 \
    -Djava.awt.headless=true \
    -Dapple.awt.UIElement=true \
    -XX:+UseParallelGC \
    -XX:+ExitOnOutOfMemoryError \
    -XX:+CrashOnOutOfMemoryError \
    --add-opens java.base/java.lang=ALL-UNNAMED \
    --add-opens java.base/java.time=ALL-UNNAMED \
    --add-opens java.base/sun.security.util=ALL-UNNAMED \
    --add-opens java.base/java.io=ALL-UNNAMED \
    --add-opens java.rmi/sun.rmi.transport=ALL-UNNAMED \
    -jar /usr/lib/unifi/lib/ace.jar start

wait
echo "WARN: unifi service process ended without being signaled? Check for errors in Log Directory." >&2
exit 1