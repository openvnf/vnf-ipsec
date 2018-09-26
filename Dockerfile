FROM golang:1.9-alpine as confd

RUN apk add --no-cache make unzip wget
RUN mkdir -p /go/src/github.com/kelseyhightower/confd && \
  ln -s /go/src/github.com/kelseyhightower/confd /app

WORKDIR /app

RUN wget -O /tmp/confd.zip https://github.com/kelseyhightower/confd/archive/v0.14.0.zip && \
    unzip -d /tmp/confd /tmp/confd.zip && \
    cp -r /tmp/confd/*/* /app && \
    rm -rf /tmp/confd* && \
    make build


FROM alpine:latest
LABEL maintainer="tobias.famulla@travelping.com"

RUN apk add --update --no-cache strongswan tcpdump iputils iproute2 && \
        mkdir -p /etc/ipsec.secrets.d && \
        mkdir -p /etc/ipsec.config.d && \
        mkdir -p /etc/confd/conf.d && \
        mkdir -p /etc/confd/templates && \
        mkdir -p /etc/confd/conf.d.disabled

COPY --from=confd /app/bin/confd /usr/local/bin/confd
COPY files/ipsec.conf /etc/ipsec.conf
COPY files/ipsec.secrets /etc/ipsec.secrets
COPY config/*.tmpl /etc/confd/templates/
COPY files/strongswan.psk-template.config.toml /etc/confd/conf.d.disabled/
COPY files/strongswan.psk-template.secret.toml /etc/confd/conf.d.disabled/
COPY files/charon.conf.toml /etc/confd/conf.d.disabled/
COPY config/farp.conf /etc/strongswan.d/charon/
COPY files/start-strongswan.sh /usr/local/bin

ENTRYPOINT ["/usr/local/bin/start-strongswan.sh"]
