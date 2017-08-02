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
    -v `pwd`/my_secrets:/etc/ipsec.secrets.d werft.tpip.net/image-vpn-s2s
```

If you do not have access to the Werft, clone this repository and build the container first:

```
$ docker build -t image-vpn-s2s .
```

and afterwards execute it as followed:

```
# docker run -it --rm --privileged --cap-add=NET_ADMIN --net=host \
    -v /lib/modules:/lib/modules \
    -v `pwd`/my_config:/etc/ipsec.config.d \
    -v `pwd`/my_secrets:/etc/ipsec.secrets.d image-vpn-s2s
```

## Configuration
To configure the Strongswan VPN container, you first have to create the folders `my_config` and `my_secret`.
Further you have to copy the example configuration from `config`, for example `config/ipsec.digitalocean.conf`, to the folder `my_config` and change it accordingly to your setup.

The documentation for the config files can be found on the [StrongSwan Website](https://wiki.strongswan.org/projects/strongswan/wiki/IpsecConf).

In the config files, the `left` side represents the site you are running the configuration on, whereas the `right` side is the remote peer.

If multiple networks have to be shared on either side, the can be concatenated in the `right|leftsubnet` like `rightsubnet=10.0.1.0/16,10.0.2.0/16`.

The secret should be copied from the `config` folder, for example `config/ipsec.azure.secrets`, to `my_secret` and changed accordingly. The first parameter in the configfile describes the IP of hostname of the peer, the secret is shared with as described in [IPSec secrets](https://wiki.strongswan.org/projects/strongswan/wiki/IpsecSecrets).

