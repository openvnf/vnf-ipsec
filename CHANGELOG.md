# Changelog

## v1.5.2

* update strongswan to strongswan:5.9.8-r1
* update base image alpine:3.17

## v1.5.1

* update strongswan to strongswan:5.9.1-r3
  fixes *CVE-2021-41990* and *CVE-2021-41991*
* update base image alpine:3.15

## v1.5.0

* update strongswan to strongswan 5.9.1-r1
* update base image alpine:3.14

## v1.4.0

* codify dependent alpine version to `3.8`
* remove usage of build container and use binary `confd` instead
* update confd to `0.16.0`
* build will fix *CVE-2018-17540*
* add MANIFEST for freezing versions

## v1.3.1

* disable `farp` plugin by default, which was desired but not executed before

## v1.3.0

* add variable for interfaces to bind to
* add charon configuration template for plugins, disable routing table and binding interfaces

## v1.2.0

* added support for mounting manually created configuration
