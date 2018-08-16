#!/bin/sh
set -eo pipefail

_initialize() {
    echo "Start: run initializations."
    _create_vti
    echo "End: run initializations."
}

_create_vti(){

# set charon.install_virtual_ip = no to prevent the daemon from also installing the VIP

    if [ -n "$IPSEC_VTI_KEY" ]; then
        echo "IPSEC_VTI_KEY set, creating VTI interface."
        set -e

        echo "Start: load ip_vti kernel module."
        if grep -qe "^ip_vti\>" /proc/modules; then
          echo "VTI module already loaded."
        else
          echo "Loading VTI module."
          modprobe ip_vti || true
        fi
        echo "End: load ip_vti kernel module."

        VTI_IF="vti${IPSEC_VTI_KEY}"

        ip tunnel add "${VTI_IF}" remote ${IPSEC_REMOTEIP} mode vti key ${IPSEC_VTI_KEY} || true
        ip link set "${VTI_IF}" up

        # add routes through the VTI interface
        if [ -n "$IPSEC_VTI_STATICROUTES" ]; then
            IFS=","
            for route in ${IPSEC_VTI_STATICROUTES}; do
                ip route add ${route} dev "${VTI_IF}" || true
            done
            unset IFS
        fi

        # vti interface address configuration
        if [ -n "$IPSEC_VTI_IPADDR_LOCAL" -a -n "$IPSEC_VTI_IPADDR_PEER" ]; then
            echo "Configuring local/peer ($IPSEC_VTI_IPADDR_LOCAL/$IPSEC_VTI_IPADDR_PEER) addresses on $VTI_IF."
            ip addr add $IPSEC_VTI_IPADDR_LOCAL peer $IPSEC_VTI_IPADDR_PEER dev $VTI_IF
        fi

        echo "Setting net.ipv4.conf.${VTI_IF}.disable_policy=1"
        sysctl -w "net.ipv4.conf.${VTI_IF}.disable_policy=1"

    fi
}

_config() {
    echo "======= Create config ======="

    # copies the template to be used
    # different templates might be used in the future depending on
    # configured values
    cp /etc/confd/conf.d.disabled/*.psk-template.* /etc/confd/conf.d
    cp /etc/confd/conf.d.disabled/charon.* /etc/confd/conf.d

    confd -onetime -backend env
    if [ -n "$DEBUG" ]
    then
        echo "======= Config ======="
        cat /etc/ipsec.config.d/*.conf
    fi
}

_config_charon() {
    echo "======= Create charon config ======="

    # copies the template to be used
    # different templates might be used in the future depending on
    # configured values
    cp /etc/confd/conf.d.disabled/charon.* /etc/confd/conf.d

    confd -onetime -backend env
    if [ -n "$DEBUG" ]
    then
        echo "======= Charon Config ======="
        cat /etc/strongswan.d/charon.conf
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
    # local and remote IP can not be "%any" if VTI needs to be created
    if [ -z "$IPSEC_VTI_KEY" ]; then
        export IPSEC_LOCALIP=${IPSEC_LOCALIP:-%any}
    fi
    export IPSEC_REMOTEIP=${IPSEC_REMOTEIP:-%any}
    export IPSEC_KEYEXCHANGE=${IPSEC_KEYEXCHANGE:-ikev2}
    export IPSEC_ESPCIPHER=${IPSEC_ESPCIPHER:-aes192gcm16-aes128gcm16-ecp256,aes192-sha256-modp3072}
    export IPSEC_IKECIPHER=${IPSEC_IKECIPHER:-aes192gcm16-aes128gcm16-prfsha256-ecp256-ecp521,aes192-sha256-modp3072}

    if [ -z "$IPSEC_REMOTEID" -a "$IPSEC_REMOTEIP" = "%any" ]
    then
        echo "if IPSEC_REMOTEIP is not set by the user, IPSEC_REMOTEID has to be set manually"
        exit 1
    elif [ -z "$IPSEC_REMOTEID" ]
    then
        export IPSEC_REMOTEID="$IPSEC_REMOTEIP"
    fi

    if [ -z "$IPSEC_LOCALID" -a "$IPSEC_LOCALIP" = "%any" ]
    then
        echo "if IPSEC_LOCALIP is not set by the user, IPSEC_LOCALID has to be set manually"
        exit 1
    elif [ -z "$IPSEC_LOCALID" ]
    then
        export IPSEC_LOCALID="$IPSEC_LOCALIP"
    fi
    return 0
}

_check_variables() {
  # we only need two varaiables for init-containers
  if [ -n "$IPSEC_VTI_KEY" ]; then
      [ -z "$IPSEC_REMOTEIP" ] && { echo "Need to set IPSEC_REMOTEIP"; exit 1; }
      [ -z "$IPSEC_REMOTENET" ] && { echo "Need to set IPSEC_REMOTENET"; exit 1; }
  else
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
  fi
  if [ -n "$IPSEC_VTI_IPADDR_PEER" -a -z "$IPSEC_VTI_IPADDR_LOCAL" ]; then
      echo "IPSEC_VTI_IPADDR_PEER cannot be used without IPSEC_VTI_IPADDR_LOCAL."
      exit 1
  fi
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
    printf "IPSEC_VTI_KEY=%s\n" $IPSEC_VTI_KEY
    printf "IPSEC_VTI_STATICROUTES=%s\n" $IPSEC_VTI_STATICROUTES
    printf "IPSEC_VTI_IPADDR_LOCAL=%s\n" $IPSEC_VTI_IPADDR_LOCAL
    printf "IPSEC_VTI_IPADDR_PEER=%s\n" $IPSEC_VTI_IPADDR_PEER
    return 0
}

trap _term TERM INT

# hook to initialize environment by file
[ -r "$ENVFILE" ] && . $ENVFILE

if [ -z "$IPSEC_USE_MANUAL_CONFIG" ]; then
    _set_default_variables
    _check_variables

    _print_variables
    _config

    if [ "$1" = "init" ]; then
        _initialize
        exit 0
    fi


    if  [ "$SET_ROUTE_DEFAULT_TABLE" = "TRUE" ]
    then
        _add_route
    fi
else
    if [ -z "$IPSEC_MANUAL_CHARON" ]; then
        _config_charon
    fi
fi

_start_strongswan

_term

