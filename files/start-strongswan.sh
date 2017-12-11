#!/bin/sh
set -eo pipefail

_config() {
    echo "======= Create config ======="

    if [ "$USE_ENV_CONFIG" = "HIDDEN_PUBIP_HOST" ]
    then
        cp /etc/confd/conf.d.disabled/*.hidden_pubip_host.* /etc/confd/conf.d
    fi

    confd -onetime -backend env
    echo "======= Config ======="
    cat /etc/ipsec.config.d/*.conf
}

_start_strongswan() {
    echo "======= start Strongswan ======="
    set +eo pipefail
    ipsec start --nofork &
    child=$!
    wait "$child"
}

if [ -n "$USE_ENV_CONFIG" ] && [ "$USE_ENV_CONFIG" = "HIDDEN_PUBIP_HOST" ]
then
    # Use AWS config template
    _remove_route() {
      echo "ip route del $IPSEC_REMOTENET via $DEFAULTROUTER dev eth0 proto static src $IPSEC_LOCALPRIVIP"
      ip route del $IPSEC_REMOTENET via $DEFAULTROUTER dev eth0 proto static src $IPSEC_LOCALPRIVIP
      return 0
    }

    _term() {
      echo "======= caught SIGTERM signal ======="
      ipsec stop
      _remove_route
      exit 0
    }

    _check_variables() {
      [ -z "$IPSEC_LOCALNET" ] && { echo "Need to set IPSEC_LOCALNET"; exit 1; }
      [ -z "$IPSEC_PSK" ] && { echo "Need to set IPSEC_PSK"; exit 1; }
      [ -z "$IPSEC_REMOTEIP" ] && { echo "Need to set IPSEC_REMOTEIP"; exit 1; }
      [ -z "$IPSEC_LOCALPRIVIP" ] && { echo "Need to set IPSEC_LOCALPRIVIP"; exit 1; }
      [ -z "$IPSEC_LOCALPUBIP" ] && { echo "Need to set IPSEC_LOCALPUBIP"; exit 1; }
      [ -z "$IPSEC_REMOTENET" ] && { echo "Need to set IPSEC_REMOTENET"; exit 1; }
      return 0
    }

    trap _term TERM INT

    _check_variables

    _config

    echo "======= setup route ======="
    DEFAULTROUTER=`ip route | head -1 | cut -d ' ' -f 3`
    echo "ip route add $IPSEC_REMOTENET via $DEFAULTROUTER dev eth0 proto static src $IPSEC_LOCALPRIVIP"
    ip route add $IPSEC_REMOTENET via $DEFAULTROUTER dev eth0 proto static src $IPSEC_LOCALPRIVIP

    _start_strongswan

    _term

else
    _term() {
        echo "======= caught SIGTERM signal ======="
        ipsec stop
        exit 0
    }

    trap _term TERM INT
    echo "======= start Strongswan ======="
    set +eo pipefail
    ipsec start --nofork &
    child=$!
    wait "$child"
    _term
fi
