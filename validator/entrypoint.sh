#!/bin/bash

CLIENT="teku"
NETWORK="gnosis"
VALIDATOR_PORT=3500
WEB3SIGNER_API="http://web3signer.web3signer-${NETWORK}.dappnode:9000"

WEB3SIGNER_RESPONSE=$(curl -s -w "%{http_code}" -X GET -H "Content-Type: application/json" -H "Host: validator.${CLIENT}-${NETWORK}.dappnode" "${WEB3SIGNER_API}/eth/v1/keystores")
HTTP_CODE=${WEB3SIGNER_RESPONSE: -3}
CONTENT=$(echo "${WEB3SIGNER_RESPONSE}" | head -c-4)

if [ "${HTTP_CODE}" == "403" ] && [ "${CONTENT}" == "*Host not authorized*" ]; then
  echo "${CLIENT} is not authorized to access the Web3Signer API. Start without pubkeys"
elif [ "$HTTP_CODE" != "200" ]; then
  echo "Failed to get keystores from web3signer, HTTP code: ${HTTP_CODE}, content: ${CONTENT}"
else
  PUBLIC_KEYS_WEB3SIGNER=($(echo "${CONTENT}" | jq -r 'try .data[].validating_pubkey'))
  if [ ${#PUBLIC_KEYS_WEB3SIGNER[@]} -gt 0 ]; then
    PUBLIC_KEYS_COMMA_SEPARATED=$(echo "${PUBLIC_KEYS_WEB3SIGNER[*]}" | tr ' ' ',')
    echo "found validators in web3signer, starting vc with pubkeys: ${PUBLIC_KEYS_COMMA_SEPARATED}"
    EXTRA_OPTS="--validators-external-signer-public-keys=${PUBLIC_KEYS_COMMA_SEPARATED} ${EXTRA_OPTS}"
  fi
fi


if [[ "$EXIT_VALIDATOR" == "I want to exit my validators" ]] && ! [ -z "$KEYSTORES_VOLUNTARY_EXIT" ]; then
    echo "Checking connectivity with the web3signer"
    WEB3SIGNER_STATUS=$(curl -s  http://web3signer.web3signer-gnosis.dappnode:9000/healthcheck | jq '.status')
    if [[ "$WEB3SIGNER_STATUS" == '"UP"' ]]; then
    echo "Proceeds to do the voluntary exit of the next keystores:"
    echo "$KEYSTORES_VOLUNTARY_EXIT"
    echo yes | exec /opt/teku/bin/teku voluntary-exit --beacon-node-api-endpoint=http://beacon-chain.teku-gnosis.dappnode:3500 \
        --validators-external-signer-public-keys=$KEYSTORES_VOLUNTARY_EXIT \
        --validators-external-signer-url=$WEB3SIGNER_API
    else
      echo "Web3signer-Gnosis is not running or Teku cannot access the Gnosis Web3signer"
      echo "The env var KEYSTORES_VOLUNTARY_EXIT: $KEYSTORES_VOLUNTARY_EXIT has a empty value"
    fi
fi

# Chek the env FEE_RECIPIENT_GNOSIS has a valid ethereum address if not set to the null address
if [ -n "$FEE_RECIPIENT_GNOSIS" ] && [[ "$FEE_RECIPIENT_GNOSIS" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
    FEE_RECIPIENT_ADDRESS="$FEE_RECIPIENT_GNOSIS"
else
    echo "FEE_RECIPIENT_GNOSIS is not set or is not a valid ethereum address, setting it to the null address"
    FEE_RECIPIENT_ADDRESS="0x0000000000000000000000000000000000000000"
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
