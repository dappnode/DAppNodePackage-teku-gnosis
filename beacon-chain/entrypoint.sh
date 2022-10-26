#!/bin/bash

# Concatenate EXTRA_OPTS string & remove trailing slash if necessary
[[ -n $CHECKPOINT_SYNC_URL ]] && EXTRA_OPTS="--initial-state=$(echo $CHECKPOINT_SYNC_URL | sed 's:/*$::')/eth/v2/debug/beacon/states/finalized ${EXTRA_OPTS}"

exec /opt/teku/bin/teku \
    --network=gnosis \
    --data-base-path=/opt/teku/data \
    --eth1-endpoint=$HTTP_WEB3PROVIDER \
    --p2p-port=$P2P_PORT \
    --rest-api-cors-origins="*" \
    --rest-api-interface=0.0.0.0 \
    --rest-api-port=$BEACON_API_PORT \
    --rest-api-host-allowlist "*" \
    --rest-api-enabled=true \
    --rest-api-docs-enabled=true \
    --metrics-enabled=true \
    --metrics-interface 0.0.0.0 \
    --metrics-port 8008 \
    --metrics-host-allowlist "*" \
    --log-destination=CONSOLE \
    --logging=$LOG_TYPE \
    $EXTRA_OPTS
