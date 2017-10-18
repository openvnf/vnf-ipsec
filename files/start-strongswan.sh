#!/bin/sh
set -euo pipefail

_remove_route() {
  echo "ip route del $IPSEC_AWS_LOCALNET via $DEFAULTROUTER dev eth0 proto static src $IPSEC_AWS_LOCALPRIVIP"
  ip route del $IPSEC_AWS_LOCALNET via $DEFAULTROUTER dev eth0 proto static src $IPSEC_AWS_LOCALPRIVIP
  return 0
}

_term() {
  echo "======= caught SIGTERM signal ======="
  kill -TERM "$child" 2>/dev/null
  wait "$child"
  _remove_route
  exit 0
}

_check_variables() {
  [ -z "$IPSEC_AWS_LOCALNET" ] && { echo "Need to set IPSEC_AWS_LOCALNET"; exit 1; }
  [ -z "$IPSEC_AWS_PSK" ] && { echo "Need to set IPSEC_AWS_PSK"; exit 1; }
  [ -z "$IPSEC_AWS_REMOTEIP" ] && { echo "Need to set IPSEC_AWS_REMOTEIP"; exit 1; }
  [ -z "$IPSEC_AWS_LOCALPRIVIP" ] && { echo "Need to set IPSEC_AWS_LOCALPRIVIP"; exit 1; }
  [ -z "$IPSEC_AWS_LOCALPUBIP" ] && { echo "Need to set IPSEC_AWS_LOCALPUBIP"; exit 1; }
  [ -z "$IPSEC_AWS_REMOTENET" ] && { echo "Need to set IPSEC_AWS_REMOTENET"; exit 1; }
  return 0
}

trap _term SIGTERM

_check_variables

echo "======= Create config ======="
confd -onetime -backend env
echo "======= Config ======="
cat /etc/ipsec.config.d/ipsec.aws.conf

echo "======= setup route ======="
DEFAULTROUTER=`ip route | head -1 | cut -d ' ' -f 3`
echo "ip route add $IPSEC_AWS_LOCALNET via $DEFAULTROUTER dev eth0 proto static src $IPSEC_AWS_LOCALPRIVIP"
ip route add $IPSEC_AWS_LOCALNET via $DEFAULTROUTER dev eth0 proto static src $IPSEC_AWS_LOCALPRIVIP

echo "======= start Strongswan ======="
ipsec start --nofork &

child=$!
wait "$child"
_remove_route
