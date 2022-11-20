ARG UPSTREAM_VERSION

########
# TEKU #
########
FROM consensys/teku:$UPSTREAM_VERSION

USER root 

COPY /security/validator-api-bearer /opt/teku/data/validator/key-manager/validator-api-bearer 
COPY /security/cert /cert
COPY entrypoint.sh /usr/bin/entrypoint.sh

RUN apt update && apt install jq ca-certificates --yes && \
    chmod +x /usr/bin/entrypoint.sh

ENV JAVA_OPTS="-Xmx4g"

ENTRYPOINT [ "entrypoint.sh" ]