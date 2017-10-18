# Site-to-site VPN Gateway using StrongSwan

This container image provides a privileged container to connect two sites
to each other running in a vm on Azure or any other node if configuration is
manually provided.

There are two different ways of running the container in current version, where the default
is the *manual way* for compatibility reasons.

If running on AWS using the *env-var* way is the recommended one.

## The *ENV-VAR* way of running Strongswan

This way there is template being used to configure the container.
Further there will be a route set by a script which is just tested on AWS yet.
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
# local private IP of the AWS node the container is supposed to be running on
IPSEC_AWS_LOCALPRIVIP
# corresponding local public IP of the AWS node
IPSEC_AWS_LOCALPUBIP
# local network to be shared over the VPN tunnel
IPSEC_AWS_LOCALNET
# public IP address of the remote node of the tunnel
IPSEC_AWS_REMOTEIP
# remote network to be shared
IPSEC_AWS_REMOTENET
# pre shared key to be used for the tunnel
# this should be a long random string
IPSEC_AWS_PSK
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
