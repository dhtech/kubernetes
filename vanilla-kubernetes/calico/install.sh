#!/bin/sh

set -e

kubectl create -f calico.yaml

# Dreamhack internal AS number (same as rojter)
calicoctl config set asNumber 64512
calicoctl create -f bgp.yaml 
