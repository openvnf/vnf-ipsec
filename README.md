# Site-to-site VPN Gateway

This container image provides a container to connect two peers
via IPsec to each other.

The current implementation uses StrongSwan but the idea is to
have the implementation details abstracted away.

This configuration should also be sufficient for every scenario where the public-ip is hidden on the virtual machine, so not visible by the `ip` command.

Testing though was just fulfiled on AWS.

Currently `--privileged` mode is a requirement, as this container will
try load missing kernel modules. Unless you can make sure all
required kernel modules are available, you also need to mount your
hosts `/lib/modules` into the container.

For other architectures, the code might have to be changed.

<!-- toc -->

* [Run this container](#run-this-container)
* [Configuration](#configuration)
  * [manual configuration](#manual-configuration)
  * [enable or disable additional modules](#enable-or-disable-additional-modules)
* [VTI Interface](#vti-interface)
* [Development](#development)
  * [freezing versions](#freezing-versions)

<!-- tocstop -->

## Run this container

To run the container execute the following section:

```
# docker run --privileged \
    -v /lib/modules:/lib/modules \
    --env-file environment.sh \
    openvnf/vnf-ipsec
```

## Configuration

Configuration is done by environment variables. See below for available options.
Alternatively it is also possible to point `$ENVFILE` to an environment file which is sourced before startup.

```sh
# source specified file before startup.
ENVFILE=

# set route for tunnel into the default routing table outside of the scope of strongswan
# use this just in conjunction with calico and host networking
SET_ROUTE_DEFAULT_TABLE=FALSE

# local IP of the node the container is supposed to be running on
# this IP has to able to be bound by the service and could also be '%any'
IPSEC_LOCALIP=

# The local identifier to be used during the handshake.
# This can either be an IP address, a FQDN, an email address or a distinguished
# name. This value has to be the same as IPSEC_REMOTEID on the other side of
# the tunnel.
IPSEC_LOCALID=

# local network to be shared over the VPN tunnel
# used for leftid=
IPSEC_LOCALNET=

# public IP address of the remote node of the tunnel
IPSEC_REMOTEIP=

# remote network to be shared
IPSEC_REMOTENET=

# the remote identifier for the connection
IPSEC_REMOTEID=

# pre shared key to be used for the tunnel
# this should be a long random string
IPSEC_PSK=

# method of key exchange
# ike | ikev1 | ikev2
IPSEC_KEYEXCHANGE=

# comma-separated list of ESP encryption/authentication algorithms to be used for the connection
# see https://wiki.strongswan.org/projects/strongswan/wiki/IKEv1CipherSuites
# or https://wiki.strongswan.org/projects/strongswan/wiki/IKEv2CipherSuites
# depending on your value for IPSEC_KEYEXCHANGE.
# example: esp=aes192gcm16-aes128gcm16-ecp256,aes192-sha256-modp3072
IPSEC_ESPCIPHER=

# comma-separated list of IKE/ISAKMP SA encryption/authentication algorithms to be used
# see https://wiki.strongswan.org/projects/strongswan/wiki/IKEv1CipherSuites
# or https://wiki.strongswan.org/projects/strongswan/wiki/IKEv2CipherSuites
# depending on your value for IPSEC_KEYEXCHANGE.
# example: aes192gcm16-aes128gcm16-prfsha256-ecp256-ecp521,aes192-sha256-modp3072
IPSEC_IKECIPHER=

# how long a particular instance of a connection (a set of encryption/authentication keys for user packets)
# should last, from successful negotiation to expiry; acceptable values are an integer optionally followed by
# s (a time in seconds) or a decimal number followed by m, h, or d (a time in minutes, hours,
# or days respectively) (default 1h, maximum 24h).
IPSEC_LIFETIME=

# how long the keying channel of a connection (ISAKMP or IKE SA) should last before being renegotiated.
# Default: 3h
IPSEC_IKELIFETIME=

# Force UDP encapsulation for ESP packets even if no NAT situation is detected.
# *yes* | no
IPSEC_FORCEUDP=

# Whether rekeying of an IKE_SA should also reauthenticate the peer.
# *yes* | no
IPSEC_IKEREAUTH=

# Interfaces to bind Charon to
# If not set, it will bind to all interfaces
# Comma seperated list (e.g. eth0,eth1,eth2)
IPSEC_INTERFACES=eth0

# uncomment the debug flag for additional debugging output
# DEBUG=yes
```

If usage of keys and certificates instead of pre shared keys should be used, the code of the repo has to be extended.

### manual configuration

It is also possible to not use environmental variables at all, but to mount
a configuration for Strongswan, the used IPSEC component manually.

Therefore the environmental variable `IPSEC_USE_MANUAL_CONFIG` has to be set
to a non empty value, for example `TRUE`.

To use the manual configuration, the corresponding files for the
[ipsec.conf](https://wiki.strongswan.org/projects/strongswan/wiki/IpsecConf)
and [ipsec.secrets](https://wiki.strongswan.org/projects/strongswan/wiki/IpsecSecrets)
have to be created.

By convention, Strongswan will read the configuration
`/etc/ipsec.config.d/ipsec.<connectionn-name>.conf` and the secret from
`/etc/ipsec.secrets.de/ipsec.<connection-name>.secrets`.

Therefore it makes sense in conjunction with Kubernetes, to mount the secrets
and the configurations to these folders.

Never the less, you are able to overwrite `/etc/ipsec.conf` and `/etc/ipsec.secrets`.

Further by default the configuration for *Charon* will be generated by a template to include configuration
for plugins, binding interfaces and setting of routes for VTIs.
The following ENVVARs are available:

* `$IPSEC_VTI_KEY`
* `$IPSEC_INTERFACES`

If you want to mount a configuration manually into the container, set `$IPSEC_MANUAL_CHARON` to anything, eg. `$IPSEC_MANUAL_CHARON=True` (unset or set to empty string will disable the option).

### enable or disable additional modules

Due to the large amount of possible module combinations in the *charon* IKE daemon,
you have to configure these manually, if you need special settings.

This includes enable plugins, which are not enabled by default and
disable plugins, which are not disabled by default.

To do so, you have to create a file with the module configuration.
As a starting point you can retrieve the current configuration from the `/etc/strongswan.d/charon`
folder of the container.

One example would be the `farp` module configuration.
The current default is:

```
farp {

    # Whether to load the plugin. Can also be an integer to increase the
    # priority of this plugin.
    load = no
}
```

To overwrite this, you have to mount the file to `/etc/strongswan.d/charon/farp.conf`
after adding you settings.

## VTI Interface

Related environment variables:

* `IPSEC_LOCALIP`
* `IPSEC_VTI_KEY`
* `IPSEC_VTI_STATICROUTES`
* `IPSEC_VTI_IPADDR_LOCAL`
* `IPSEC_VTI_IPADDR_PEER`

If the entrypoint is provided the argument `init`, an initialisation-container is started that can create a VTI tunnel to route
the IPSEC traffic over.

To create a VTI interface, set the environment variable `IPSEC_VTI_KEY` to an integer.

A VTI tunnel interface is then created with `IPSEC_LOCALIP` as local endpoint and `IPSEC_VTI_KEY` as key.

The parameter `IPSEC_VTI_KEY` must then be the same when starting the container in default mode to set the value as mark in the
IPSec connection configuration.

All comma-separated values of `IPSEC_VTI_STATICROUTES` are added as static routes via the created VTI tunnel.

To configure p2p addresses (local/peer) on the vti interface use `IPSEC_VTI_IPADDR_LOCAL` and `IPSEC_VTI_IPADDR_PEER` respectively.

## Development

### freezing versions

To upgrade the versions of the packages to new versions, you should run
`apk update && apk upgrade` in a container of an already created image.

To freeze the versions, execute `freeze_apk_versions` and copy the updated
`/root/MANIFEST` to this repository and create a commit.
