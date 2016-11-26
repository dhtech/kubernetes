#!/bin/sh


for ns in $(kubectl get namespace -o name | cut -f 2 -d '/')
do
  for thing in $(kubectl get 2>&1 | awk '/    \* / {print $2}')
  do
    kubectl get "$thing" --namespace="$ns" -o yaml > "kube-$ns-$thing.yaml"
  done
done
