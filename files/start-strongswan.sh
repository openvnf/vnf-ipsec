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

# Set default mode
: ${USE_ENV_CONFIG:=HIDDEN_PUBIP_HOST}

if [ -n "$USE_ENV_CONFIG" ] && [ "$USE_ENV_CONFIG" = "HIDDEN_PUBIP_HOST" ]
then
    _remove_route() {
        echo "ip route del $IPSEC_REMOTENET via $DEFAULTROUTER dev eth0 proto static src $IPSEC_LOCALPRIVIP"
        ip route del $IPSEC_REMOTENET via $DEFAULTROUTER dev eth0 proto static src $IPSEC_LOCALPRIVIP
        return 0
    }

    _add_route() {
        echo "======= setup route ======="
        DEFAULTROUTER=`ip route | head -1 | cut -d ' ' -f 3`
        echo "ip route add $IPSEC_REMOTENET via $DEFAULTROUTER dev eth0 proto static src $IPSEC_LOCALPRIVIP"
        ip route add $IPSEC_REMOTENET via $DEFAULTROUTER dev eth0 proto static src $IPSEC_LOCALPRIVIP
    }

    _term() {
        echo "======= caught SIGTERM signal ======="
        ipsec stop
        if [ -n "$SET_ROUTE_DEFAULT_TABLE" ] && [ "$SET_ROUTE_DEFAULT_TABLE" = "TRUE" ]
        then
            _remove_route
        fi
        exit 0
    }

    _set_default_variables() {
        : ${IPSEC_REMOTE_IP:=%any}
        : ${IPSEC_LOCALIP:=%any}
        : ${IPSEC_KEYEXCHANGE:=ikev2}
        : ${IPSEC_ESPCIPHER:=aes192gcm16-aes128gcm16-ecp256,aes192-sha256-modp3072}
        : ${IPSEC_IKECIPHER:=aes192gcm16-aes128gcm16-prfsha256-ecp256-ecp521,aes192-sha256-modp3072}
        return 0
    }

    _check_variables() {
      [ -z "$IPSEC_LOCALNET" ] && { echo "Need to set IPSEC_LOCALNET"; exit 1; }
      [ -z "$IPSEC_PSK" ] && { echo "Need to set IPSEC_PSK"; exit 1; }
      [ -z "$IPSEC_REMOTEIP" ] && { echo "Need to set IPSEC_REMOTEIP"; exit 1; }
      [ -z "$IPSEC_REMOTEID" ] && { echo "Need to set IPSEC_REMOTEID"; exit 1; }
      [ -z "$IPSEC_LOCALIP" ] && { echo "Need to set IPSEC_LOCALIP"; exit 1; }
      [ -z "$IPSEC_LOCALID" ] && { echo "Need to set IPSEC_LOCALID"; exit 1; }
      [ -z "$IPSEC_REMOTENET" ] && { echo "Need to set IPSEC_REMOTENET"; exit 1; }
      [ -z "$IPSEC_KEYEXCHANGE" ] && { echo "Need to set IPSEC_KEYEXCHANGE"; exit 1; }
      [ -z "$IPSEC_ESPCIPHER" ] && { echo "Need to set IPSEC_ESPCIPHER"; exit 1; }
      [ -z "$IPSEC_IKECIPHER" ] && { echo "Need to set IPSEC_IKECIPHER"; exit 1; }
      return 0
    }

    _print_variables() {
        echo "======= set variables ======="
        printf "IPSEC_LOCALNET = %s\n" $IPSEC_LOCALNET
        printf "IPSEC_LOCALIP = %s\n" $IPSEC_LOCALIP
        printf "IPSEC_LOCALID = %s\n" $IPSEC_LOCALID
        printf "IPSEC_REMOTEID = %s\n" $IPSEC_REMOTEID
        printf "IPSEC_REMOTEIP = %s\n" $IPSEC_REMOTEIP
        printf "IPSEC_REMOTENET = %s\n" $IPSEC_REMOTENET
        printf "IPSEC_PSK = %s\n" $IPSEC_PSK
        printf "IPSEC_KEYEXCHANGE = %s\n" $IPSEC_KEYEXCHANGE
        printf "IPSEC_ESPCIPHER = %s\n" $IPSEC_ESPCIPHER
        printf "IPSEC_IKECIPHER = %s\n" $IPSEC_IKECIPHER
        return 0
    }

    trap _term TERM INT

    _set_default_variables
    _check_variables

    _print_variables

    _config

    if [ -n "$SET_ROUTE_DEFAULT_TABLE" ] && [ "$SET_ROUTE_DEFAULT_TABLE" = "TRUE" ]
    then
        _add_route
    fi

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
