#!/bin/bash

NETWORK="gnosis"
VALIDATOR_PORT=3500
WEB3SIGNER_API="http://web3signer.web3signer-${NETWORK}.dappnode:9000"

# MEVBOOST: https://docs.teku.consensys.net/en/latest/HowTo/Builder-Network/
if [ -n "$_DAPPNODE_GLOBAL_MEVBOOST_GNOSIS" ] && [ "$_DAPPNODE_GLOBAL_MEVBOOST_GNOSIS" == "true" ]; then
  echo "MEVBOOST is enabled"
  MEVBOOST_URL="http://mev-boost.mev-boost-gnosis.dappnode:18550"
  if curl --retry 5 --retry-delay 5 --retry-all-errors "${MEVBOOST_URL}"; then
    EXTRA_OPTS="--validators-builder-registration-default-enabled ${EXTRA_OPTS}"
  else
    echo "MEVBOOST is enabled but ${MEVBOOST_URL} is not reachable"
    curl -X POST -G 'http://my.dappnode/notification-send' --data-urlencode 'type=danger' --data-urlencode title="${MEVBOOST_URL} is not available" --data-urlencode 'body=Make sure the MEV-Boost package is available and running'
  fi
fi

if [[ "$EXIT_VALIDATOR" == "I want to exit my validators" ]] && ! [ -z "$KEYSTORES_VOLUNTARY_EXIT" ]; then
    echo "Check connectivity with the web3signer"
    WEB3SIGNER_STATUS=$(curl -s  http://web3signer.web3signer-gnosis.dappnode:9000/healthcheck | jq '.status')
    if [[ "$WEB3SIGNER_STATUS" == '"UP"' ]]; then
    echo "Proceeds to do the voluntary exit of the next keystores:"
    echo "$KEYSTORES_VOLUNTARY_EXIT"
    echo yes | exec /opt/teku/bin/teku voluntary-exit --beacon-node-api-endpoint=http://beacon-chain.teku-gnosis.dappnode:3500 \
        --validators-external-signer-public-keys=$KEYSTORES_VOLUNTARY_EXIT \
        --validators-external-signer-url=$WEB3SIGNER_API
    else
      echo "The web3signer-gnosis is not running or the teku package has not access to the web3signer"
      echo "The env var KEYSTORES_VOLUNTARY_EXIT: $KEYSTORES_VOLUNTARY_EXIT has a empty value"
    fi
fi

#Handle Graffiti Character Limit
oLang=$LANG oLcAll=$LC_ALL
LANG=C LC_ALL=C 
graffitiString=${GRAFFITI:0:32}
LANG=$oLang LC_ALL=$oLcAll

# Teku must start with the current env due to JAVA_HOME var
exec /opt/teku/bin/teku --log-destination=CONSOLE \
  validator-client \
  --network=${NETWORK} \
  --data-base-path=/opt/teku/data \
  --beacon-node-api-endpoint="$BEACON_NODE_ADDR" \
  --validators-external-signer-url="$WEB3SIGNER_API" \
  --metrics-enabled=true \
  --metrics-interface 0.0.0.0 \
  --metrics-port 8008 \
  --metrics-host-allowlist=* \
  --validator-api-enabled=true \
  --validator-api-interface=0.0.0.0 \
  --validator-api-port="$VALIDATOR_PORT" \
  --validator-api-host-allowlist=* \
  --validators-graffiti="${graffitiString}" \
  --validators-proposer-default-fee-recipient="${FEE_RECIPIENT_ADDRESS}" \
  --validator-api-keystore-file=/cert/teku_client_keystore.p12 \
  --validator-api-keystore-password-file=/cert/teku_keystore_password.txt \
  --logging=${LOG_TYPE} \
  ${EXTRA_OPTS}
