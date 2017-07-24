FROM alpine:latest
LABEL maintainer="tobias.famulla@travelping.com"

RUN apk add --update --no-cache strongswan strongswan-dbg
# docker run --privileged --cap-add=NET_ADMIN -v /lib/modules:/lib/modules
