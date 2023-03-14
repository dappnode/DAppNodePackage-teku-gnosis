#!/bin/bash

# Concatenate EXTRA_OPTS string & remove trailing slash if necessary
[[ -n $CHECKPOINT_SYNC_URL ]] && EXTRA_OPTS="--initial-state=$(echo $CHECKPOINT_SYNC_URL | sed 's:/*$::')/eth/v2/debug/beacon/states/finalized ${EXTRA_OPTS}"

case $_DAPPNODE_GLOBAL_EXECUTION_CLIENT_GNOSIS in
"nethermind-xdai.dnp.dappnode.eth")
  HTTP_ENGINE="http://nethermind-xdai.dappnode:8551"
  ;;
"erigon-gnosis.dnp.dappnode.eth")
  HTTP_ENGINE="http://erigon-gnosis.dappnode:8551"
  ;;
*)
  echo "Unknown value for _DAPPNODE_GLOBAL_EXECUTION_CLIENT_GNOSIS: $_DAPPNODE_GLOBAL_EXECUTION_CLIENT_GNOSIS"
  # TODO: this default value must be temporary and changed once there are mor than 1 EC
  HTTP_ENGINE="http://nethermind-xdai.dappnode:8551"
  ;;
esac

# Chek the env FEE_RECIPIENT_GNOSIS has a valid ethereum address if not set to the null address
if [ -n "$FEE_RECIPIENT_GNOSIS" ] && [[ "$FEE_RECIPIENT_GNOSIS" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
    FEE_RECIPIENT_ADDRESS="$FEE_RECIPIENT_GNOSIS"
else
    echo "FEE_RECIPIENT_GNOSIS is not set or is not a valid ethereum address, setting it to the null address"
    FEE_RECIPIENT_ADDRESS="0x0000000000000000000000000000000000000000"
fi

exec /opt/teku/bin/teku \
    --network=gnosis \
    --data-base-path=/opt/teku/data \
    --ee-endpoint=$HTTP_ENGINE \
    --ee-jwt-secret-file="/jwtsecret" \
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
    --validators-proposer-default-fee-recipient="${FEE_RECIPIENT_ADDRESS}" \
    $EXTRA_OPTS
