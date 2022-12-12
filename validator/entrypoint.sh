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
  --validators-graffiti="${GRAFFITI}" \
  --validators-proposer-default-fee-recipient="${FEE_RECIPIENT_ADDRESS}" \
  --validator-api-keystore-file=/cert/teku_client_keystore.p12 \
  --validator-api-keystore-password-file=/cert/teku_keystore_password.txt \
  --logging=${LOG_TYPE} \
  --p2p-discovery-bootnodes=enr:-Ly4QClooKhmB409-xLE52rTmC2h9kZBO_VFXR-kjqLDdduuZoxsjfwTxa1jscQMBpqmezG_JCwPpEzEYRM_1UCy-0gCh2F0dG5ldHOIAAAAAAAAAACEZXRoMpCCS-QxAgAAZP__________gmlkgnY0gmlwhKXoiruJc2VjcDI1NmsxoQLLYztVAaOL2dhsQf884Vth9ro6n9p2yj-osPfZ0L_NwYhzeW5jbmV0cwCDdGNwgiMog3VkcIIjKA,enr:-Ly4QHO5_3Zuosjt9IJQF3ovGroSWyB4rMZFUulOl5R5PkjcfVwtYewEp2TvUpo9tvHYMGKpDxgAYmjjTJcGasqn9uoCh2F0dG5ldHOIAAAAAAAAAACEZXRoMpCCS-QxAgAAZP__________gmlkgnY0gmlwhI_GnBiJc2VjcDI1NmsxoQJqvGdusfukoXNx3F84umajVgkfVs0wasHeY45qcYgwf4hzeW5jbmV0cwCDdGNwgiMog3VkcIIjKA,enr:-Ly4QPd8v1jzDOHuEAEJ-NPgbLgRRbsuuz4KZOSZ2YiIaD0dQ-BMbbzEw0Cix5wst0suFVrsrB73dg0_980zpbKKzzEBh2F0dG5ldHOIAAAAAAAAAACEZXRoMpCCS-QxAgAAZP__________gmlkgnY0gmlwhJ_f1T2Jc2VjcDI1NmsxoQNdZWlOxiBbJltPxilQgdllvE_cNF6sC1bpyRUyWegVjohzeW5jbmV0cwCDdGNwgiMog3VkcIIjKA,enr:-Ly4QAOrFTIBlS__dwh0hhMLcGB-mbRTgMJc1P4MfMyd15-dX75_TBq7RsqWMLsZzdidoU41zO0fvI8-w7N8dHrpA54Bh2F0dG5ldHOIAAAAAAAAAACEZXRoMpCCS-QxAgAAZP__________gmlkgnY0gmlwhLI-woiJc2VjcDI1NmsxoQKeJ-BUNBGaVYX1MgnAsvjgJpGXVKgEMZa1_FMG8fTYl4hzeW5jbmV0cwCDdGNwgiMog3VkcIIjKA,enr:-Ly4QM0mWWtb978oZpY46_DVEY9SOkyDKprDlu6NyI6cjRX0TDYGp9txkyREyRw3mIkXWFDsdhONUZqKzjD09lp3iLIBh2F0dG5ldHOIAAAAAAAAAACEZXRoMpCCS-QxAgAAZP__________gmlkgnY0gmlwhLI-wMOJc2VjcDI1NmsxoQNXBYeo4Oa9Hksc247JWokwgpZAJzZxWMMK1KG3UYl4w4hzeW5jbmV0cwCDdGNwgiMog3VkcIIjKA,enr:-Ly4QDnJWKfiGm6U6SyLr8r-BfM6zHlI90VPsgbxiXb6GhIUVcDmeGw_IRxLpUAelnu2sH8TtF9uenfIGdAshoUZHAUBh2F0dG5ldHOIAAAAAAAAAACEZXRoMpCCS-QxAgAAZP__________gmlkgnY0gmlwhKdj0Q6Jc2VjcDI1NmsxoQIrmmOVYy87sV-n8x8QxfCKLsf_eKqwk6Rl5Gj-YLV8wYhzeW5jbmV0cwCDdGNwgiMog3VkcIIjKA,enr:-L24QJHzedzjOM6Xm53qSdrbP635LvqpxFCJy_2T84rZvVVjV81kS_kRKp7vV_PFPS2EHdSzpXtDMJCugvzdhjRZeGkGh2F0dG5ldHOIAAAAAAAAAACEZXRoMpCCS-QxAgAAZP__________gmlkgnY0gmlwhIm45FOJc2VjcDI1NmsxoQPHxbRx1Ev72MVVUergKeLznxrchLhB3lK9ljWCbCuGWYhzeW5jbmV0c4gAAAAAAAAAAIN0Y3CCIyg,enr:-L24QK00qalnMGv7PVg5k9Z7OjPFhIFoHLm6SDP8DjKOgFO5aUHzCqecoA9S3Y_0nI8mOF8sF1mYqYEE7byacE1Vq6YGh2F0dG5ldHOIAAAAAAAAAACEZXRoMpCCS-QxAgAAZP__________gmlkgnY0gmlwhKRcYG-Jc2VjcDI1NmsxoQPUtWI-6bkId_18Hy0KCautFQ5GJD-f2cgYCqNS5EekRIhzeW5jbmV0c4gAAAAAAAAAAIN0Y3CCIyg,enr:-L24QPdWmlPHi-0fQKptAjtkhKG50novgUHWeP5amyi_lGSWcQPAahWl7Ci3kW2p1Sd6WRtqlgkxSyvc6wioeaQl9ZIGh2F0dG5ldHOIAAAAAAAAAACEZXRoMpCCS-QxAgAAZP__________gmlkgnY0gmlwhLI-xGiJc2VjcDI1NmsxoQLNCuDR6ik6JcTW8uAsoPn6AMgtNvGq65kCnJmA2HY2JIhzeW5jbmV0c4gAAAAAAAAAAIN0Y3CCIyg,enr:-L24QICiK4pSRAOgkO7R3yQVbjJXGVt1vbdvXsom0yA-UqlMIHO98f8tZyEKbz0lrgrdy89Vw_agSKzuGS7Hgi3QsygGh2F0dG5ldHOIAAAAAAAAAACEZXRoMpCCS-QxAgAAZP__________gmlkgnY0gmlwhJ_f1aaJc2VjcDI1NmsxoQKyGQswAJ5pJaPF9WRpGU4Lp8CdxiSlm8AHJsr1naz_7YhzeW5jbmV0c4gAAAAAAAAAAIN0Y3CCIyg,enr:-KG4QKWOgedErRLsanl1AUjTFnHB-RO9OsyFP-vtSrX2VGxRBdvoJVrzBJwgGYLIBiDjqy0eYJ2r8ZosAjkWhQ02koUGhGV0aDKQgkvkMQIAAGT__________4JpZIJ2NIJpcISf39WdiXNlY3AyNTZrMaEDYAuZlJpKwWdGtbSrVgy6N5sdMjehVglGMGGkBCFg_VeDdGNwgiMog3VkcIIjKA,enr:-KG4QBart9YQV5Ju3EMxUUnJ0ntgYf7J6jDbEPySiR7R8gJ9DcTp22gArHqWSMQVyt0-TMnuZrZQCprcaka5J8B9JN8GhGV0aDKQgkvkMQIAAGT__________4JpZIJ2NIJpcISf39G5iXNlY3AyNTZrMaED13MHlUcbr4978YYNRurZtykey8gTY_O5pQ4a427ZICuDdGNwgiMog3VkcIIjKA,enr:-KG4QLk-EkZCAjhMaBSlB4r6Icrz137hIx6WXg5AKIXQl9vkPt876WxIhzu8dVPCLVfaPzjAsIjXeBUPy2E3VH4QEuEGhGV0aDKQgkvkMQIAAGT__________4JpZIJ2NIJpcISf39n5iXNlY3AyNTZrMaECtocMlfvwxqouGi13SSdG6Tkn3shkyBQt1BIpF0fhXc-DdGNwgiMog3VkcIIjKA,enr:-KG4QDXI2zubDpp7QowlafGwwTLu4w-gFztFYNnA6_I0vrpaS9bXQydY_Gh8Dc6c7cy9SHEi56HRfle9jkKIbSRQ2B8GhGV0aDKQgkvkMQIAAGT__________4JpZIJ2NIJpcISf39WiiXNlY3AyNTZrMaECZ2_0tLZ9kb0Wn-lVNcZEyhVG9dmXX_xzQXQq24sdbZiDdGNwgiMog3VkcIIjKA,enr:-LK4QPnudCfJYvcmV-LjJBU5jexY3QTdC1PepWK08OHb4w_BJ3OgFbh0Bc2nb1WRK6p2CBNOPAixpPrtAvmNQPgegDgBh2F0dG5ldHOIAAAAAAAAAACEZXRoMpBW_bXgAQAAZP__________gmlkgnY0gmlwhJO2zMWJc2VjcDI1NmsxoQKk8-B9o94CY2UUK2bxPpl-T_yHmTtE7rAPaT26M4w09YN0Y3CCIyiDdWRwgiMo,enr:-LK4QArhQjC_S3CwptV7balWpNP5IVKweAqZzvq93vz_zN_ZSruOxBU5ECgqOBUFHO1nYUveOYVeiEKswg637rOURDABh2F0dG5ldHOIAAAAAAAAAACEZXRoMpBW_bXgAQAAZP__________gmlkgnY0gmlwhIm4t0GJc2VjcDI1NmsxoQIj9iJm4h7OAhhCoUcqfn41_fj9F7UfKnISj_-xqKH834N0Y3CCIyiDdWRwgiMo,enr:-Ly4QMU1y81COwm1VZgxGF4_eZ21ub9-GHF6dXZ29aEJ0oZpcV2Rysw-viaEKfpcpu9ZarILJLxFZjcKOjE0Sybs3MQBh2F0dG5ldHOIAAAAAAAAAACEZXRoMpCCS-QxAgAAZP__________gmlkgnY0gmlwhANLnx-Jc2VjcDI1NmsxoQKoaYT8I-wf2I_f_ii6EgoSSXj5T3bhiDyW-7ZLsY3T64hzeW5jbmV0cwCDdGNwgiMog3VkcIIjKA,enr:-Ly4QJcPfzPTwhknVlYmCMYo1vtOqItLLV9iiydSuMYoCcJ6G38V6JiJaRNQUTR-1sivBsJIESP9A4KhoO_k9vOR9ZoBh2F0dG5ldHOIAAAAAAAAAACEZXRoMpCCS-QxAgAAZP__________gmlkgnY0gmlwhBLGgjaJc2VjcDI1NmsxoQPKKRjNBuhorFa1FbCJ8xgkbhu5Jm-uYyafBiLIN-mIiYhzeW5jbmV0cwCDdGNwgiMog3VkcIIjKA,enr:-Ly4QLjZUWdqUO_RwyDqCAccIK5-MbLRD6A2c7oBuVbBgBnWDkEf0UKJVAaJqi2pO101WVQQLYSnYgz1Q3pRhYdrlFoBh2F0dG5ldHOIAAAAAAAAAACEZXRoMpCCS-QxAgAAZP__________gmlkgnY0gmlwhANA8sSJc2VjcDI1NmsxoQK4TC_EK1jSs0VVPUpOjIo1rhJmff2SLBPFOWSXMwdLVYhzeW5jbmV0cwCDdGNwgiMog3VkcIIjKA,enr:-Ly4QKwX2rTFtKWKQHSGQFhquxsxL1jewO8JB1MG-jgHqAZVFWxnb3yMoQqnYSV1bk25-_jiLuhIulxar3RBWXEDm6EBh2F0dG5ldHOIAAAAAAAAAACEZXRoMpCCS-QxAgAAZP__________gmlkgnY0gmlwhAN-qZeJc2VjcDI1NmsxoQI7EPGMpecl0QofLp4Wy_lYNCCChUFEH6kY7k-oBGkPFIhzeW5jbmV0cwCDdGNwgiMog3VkcIIjKA \
  ${EXTRA_OPTS}
