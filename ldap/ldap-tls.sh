#!/bin/sh

kubectl create secret generic ldap-tls -n ldap \
  --from-file=ca.crt --from-file=server.crt --from-file=server.key
