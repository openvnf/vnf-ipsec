FROM alpine:3.8
LABEL maintainer="tobias.famulla@travelping.com"

RUN apk add --update --no-cache strongswan tcpdump iputils iproute2 wget && \
        mkdir -p /etc/ipsec.secrets.d && \
        mkdir -p /etc/ipsec.config.d && \
        mkdir -p /etc/confd/conf.d && \
        mkdir -p /etc/confd/templates && \
        mkdir -p /etc/confd/conf.d.disabled

RUN wget -O confd https://github.com/kelseyhightower/confd/releases/download/v0.16.0/confd-0.16.0-linux-amd64 && \
        echo "255d2559f3824dd64df059bdc533fd6b697c070db603c76aaf8d1d5e6b0cc334  confd" | sha256sum -c - && \
        mv confd /usr/local/bin/ && \
        chmod +x /usr/local/bin/confd

COPY files/ipsec.conf /etc/ipsec.conf
COPY files/ipsec.secrets /etc/ipsec.secrets
COPY config/*.tmpl /etc/confd/templates/
COPY files/strongswan.psk-template.config.toml /etc/confd/conf.d.disabled/
COPY files/strongswan.psk-template.secret.toml /etc/confd/conf.d.disabled/
COPY files/charon.conf.toml /etc/confd/conf.d.disabled/
COPY config/farp.conf /etc/strongswan.d/charon/
COPY files/start-strongswan.sh /usr/local/bin

ENTRYPOINT ["/usr/local/bin/start-strongswan.sh"]
