# Site-to-site VPN Gateway using StrongSwan

This container image provides a privileged container to connect two sites
to each other running in a vm on Azure.

To execute this container, the files `ipsec.conf` and `ipsec.secret` have to be
created and mounted into the container.

To execute the container run the following:
```
# docker run -it --rm --privileged --cap-add=NET_ADMIN --net=host \
    -v /lib/modules:/lib/modules -v `pwd`/my_config:/etc/ipsec.docker.d/ werft.tpip.net/image-vpn-s2s
```

Examples of these configfiles can be found in the `config` folder.
