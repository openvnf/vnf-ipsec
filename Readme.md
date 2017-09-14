# Site-to-site VPN Gateway using StrongSwan

This container image provides a privileged container to connect two sites
to each other running in a vm on Azure.

## Run this container

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
    -v `pwd`/my_secrets:/etc/ipsec.secrets.d werft.tpip.net/cennso/image-vpn-s2s
```

## Configuration
To configure the Strongswan VPN container, you first have to create the folders `my_configs` and `my_secrets`.
Further you have to copy the example configuration from `config`, for example `config/ipsec.digitalocean.conf`, to the folder `my_configs` and change it accordingly to your setup.
The files in this directory must match the naming-scheme `ipsec.<your-identifier>.conf`.

The documentation for the config files can be found on the [StrongSwan Website](https://wiki.strongswan.org/projects/strongswan/wiki/IpsecConf).

In the config files, the `left` side represents the site you are running the configuration on, whereas the `right` side is the remote peer.

If multiple networks have to be shared on either side, the can be concatenated in the `right|leftsubnet` like `rightsubnet=10.0.1.0/16,10.0.2.0/16`.

The secret should be copied from the `config` folder, for example `config/ipsec.azure.secrets`, to `my_secrets` and changed accordingly. The first parameter in the secrets files describes the IP or hostname of the peer, the secret is shared as described in [IPSec secrets](https://wiki.strongswan.org/projects/strongswan/wiki/IpsecSecrets).
The files in this directory must match the naming-scheme `ipsec.<your-identifier>.secrets`.
