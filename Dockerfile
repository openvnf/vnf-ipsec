FROM alpine:latest
LABEL maintainer="tobias.famulla@travelping.com"

RUN apk add --update --no-cache strongswan && \
        mkdir -p /etc/ipsec.secrets.d/ && \
        mkdir -p /etc/ipsec.config.d/
ADD files/ipsec.conf /etc/ipsec.conf
ADD files/ipsec.secrets /etc/ipsec.secrets

CMD ipsec start --nofork
