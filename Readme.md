# Site-to-site VPN Gateway using StrongSwan

This container image provides a container to connect two sites
to each other.

There are two different ways of running the container in current version, where the default
is the *manual way* for compatibility reasons.
In general this way can be used with every configuration accepted by the *strongswan* software
and is therefor quite useful for testing and development on new architectures.

If running on AWS using the *env-var* way is the recommended one.
This configuration should also be sufficient for every scenario where the public-ip is hidden on the virtual machine, so not visible by the `ip` command.

Testing though was just fulfiled on AWS.

## The *ENV-VAR* way of running Strongswan

This way there is template being used to configure the container.

An option to create routes in the default routing table is also provided.
It has to be used, if routing of the tunneled networks should happen automatically when using *calico*.
For this to be working, the network has though to be accepted by calico and the container has to
run using host networking. 

If running as a container without host networking, just adding CAP_NET_ADMIN is sufficient but
useful termination of the traffic inside the container has to be taken care of by the user.

For other architectures, the code might have to be changed.

### Run this container

If you have access to Travelping Werft, log in to it first.

Afterwards create a file containing the environmental variables to run this
container as described below.
To run the container execute the following section:

```
# docker run -it --rm --privileged --cap-add=NET_ADMIN --net=host \
    -v /lib/modules:/lib/modules \
    --env-file environment.sh \
    werft.tpip.net/cennso/image-vpn-s2s
```

If using the host networking is not necessary, just ommit the parameters `--privileged` and `--net=host`.

If you do not have access to the Werft, clone this repository and build the container first:

```
$ docker build -t image-vpn-s2s .
```

and afterwards execute it as followed:

```
# docker run -it --rm --privileged --cap-add=NET_ADMIN --net=host \
    -v /lib/modules:/lib/modules \
    --env-file environment.sh \
    image-vpn-s2s
```

### Configuration

You have to create a file containing the environmental variables you want to configure:

```sh
# configuration variables for Strongswan VPN image
# set this variable to switch to env-var mode for AWS
USE_ENV_CONFIG=AWS

# set route for tunnel into the default routing table outside of the scope of strongswan
# use this just in conjunction with calico and host networking
SET_ROUTE_DEFAULT_TABLE=FALSE

# local private IP of the AWS node the container is supposed to be running on
IPSEC_LOCALPRIVIP=

# corresponding local public IP of the AWS node
IPSEC_LOCALPUBIP=

# local network to be shared over the VPN tunnel
# used for leftid=
IPSEC_LOCALNET=

# public IP address of the remote node of the tunnel
IPSEC_REMOTEIP=

# remote network to be shared
IPSEC_REMOTENET=

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

# Force UDP encapsulation for ESP packets even if no NAT situation is detected.
# *yes* | no
IPSEC_FORCEUDP=
```

If usage of keys and certificates instead of pre shared keys should be used, the code of the repo has to be extended.

## The *manual configration* way of running Strongswan

This way gives you the full flexibility provided by the `ipsec.conf` files of Strongswan.
Though it is discouraged to be used on AWS for simple site-to-site links,
because the configuration can be cumbersome and can not be tested in all possible combinations.
Furter the user has to have some knowledge of Strongswan configuration.

### Run this container

If you have access to Travelping Werft, log in to it first.

Afterwards configure the VPN settings as described in the following section.
To run the container execute the following section:

```
# docker run -it --rm --privileged --cap-add=NET_ADMIN --net=host \
    -v /lib/modules:/lib/modules \
    -v `pwd`/my_config:/etc/ipsec.config.d \
    -v `pwd`/my_secrets:/etc/ipsec.secrets.d werft.tpip.net/cennso/image-vpn-s2s
```

If you do not have access to the Werft, clone this repository and build the container first:

```
$ docker build -t image-vpn-s2s .
```

and afterwards execute it as followed:

```
# docker run -it --rm --privileged --cap-add=NET_ADMIN --net=host \
    -v /lib/modules:/lib/modules \
    -v `pwd`/my_configs:/etc/ipsec.config.d \
    -v `pwd`/my_secrets:/etc/ipsec.secrets.d image-vpn-s2s
```

### Configuration
To configure the Strongswan VPN container, you first have to create the folders `my_configs` and `my_secrets`.
Further you have to copy the example configuration from `config`, for example `config/ipsec.digitalocean.conf`, to the folder `my_configs` and change it accordingly to your setup.
The files in this directory must match the naming-scheme `ipsec.<your-identifier>.conf`.

The documentation for the config files can be found on the [StrongSwan Website](https://wiki.strongswan.org/projects/strongswan/wiki/IpsecConf).

In the config files, the `left` side represents the site you are running the configuration on, whereas the `right` side is the remote peer.

If multiple networks have to be shared on either side, the can be concatenated in the `right|leftsubnet` like `rightsubnet=10.0.1.0/16,10.0.2.0/16`.

The secret should be copied from the `config` folder, for example `config/ipsec.azure.secrets`, to `my_secrets` and changed accordingly. The first parameter in the secrets files describes the IP or hostname of the peer, the secret is shared as described in [IPSec secrets](https://wiki.strongswan.org/projects/strongswan/wiki/IpsecSecrets).
The files in this directory must match the naming-scheme `ipsec.<your-identifier>.secrets`.
