#!/bin/sh
set -eo pipefail

_config() {
    echo "======= Create config ======="

    # copies the template to be used
    # different templates might be used in the future depending on
    # configured values
    cp /etc/confd/conf.d.disabled/*.psk-template.* /etc/confd/conf.d

    confd -onetime -backend env
    if [ -n "$DEBUG" ]
    then
        echo "======= Config ======="
        cat /etc/ipsec.config.d/*.conf
    fi 
}

_start_strongswan() {
    echo "======= start VPN ======="
    set +eo pipefail
    ipsec start --nofork &
    child=$!
    wait "$child"
}

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
    export IPSEC_REMOTEIP=${IPSEC_REMOTEIP:-%any}
    export IPSEC_LOCALIP=${IPSEC_LOCALIP:-%any}
    export IPSEC_KEYEXCHANGE=${IPSEC_KEYEXCHANGE:-ikev2}
    export IPSEC_ESPCIPHER=${IPSEC_ESPCIPHER:-aes192gcm16-aes128gcm16-ecp256,aes192-sha256-modp3072}
    export IPSEC_IKECIPHER=${IPSEC_IKECIPHER:-aes192gcm16-aes128gcm16-prfsha256-ecp256-ecp521,aes192-sha256-modp3072}
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
    printf "IPSEC_LOCALNET=%s\n" $IPSEC_LOCALNET
    printf "IPSEC_LOCALIP=%s\n" $IPSEC_LOCALIP
    printf "IPSEC_LOCALID=%s\n" $IPSEC_LOCALID
    printf "IPSEC_REMOTEID=%s\n" $IPSEC_REMOTEID
    printf "IPSEC_REMOTEIP=%s\n" $IPSEC_REMOTEIP
    printf "IPSEC_REMOTENET=%s\n" $IPSEC_REMOTENET
    printf "IPSEC_PSK=%s\n" $IPSEC_PSK
    printf "IPSEC_KEYEXCHANGE=%s\n" $IPSEC_KEYEXCHANGE
    printf "IPSEC_ESPCIPHER=%s\n" $IPSEC_ESPCIPHER
    printf "IPSEC_IKECIPHER=%s\n" $IPSEC_IKECIPHER
    return 0
}

trap _term TERM INT

_set_default_variables
_check_variables

_print_variables

_config

if  [ "$SET_ROUTE_DEFAULT_TABLE" = "TRUE" ]
then
    _add_route
fi

_start_strongswan

_term

