#!/bin/sh


for ns in $(kubectl get namespace -o name | cut -f 2 -d '/')
do
  for thing in $(kubectl get 2>&1 | awk '/    \* / {print $2}')
  do
    kubectl get "$thing" --namespace="$ns" -o yaml > "kube-$ns-$thing.yaml"
  done
done

for ns in $(kubectl get namespace -o name | cut -f 2 -d '/')
do
  echo "Saving logs for namespace $ns"
  for pod in $(kubectl get pods --namespace="$ns" -o name | cut -f 2 -d '/')
  do
    kubectl logs --namespace="$ns" $pod > logs-"$ns"-"$pod".log
    kubectl logs --namespace="$ns" -p $pod > logs-"$ns"-"$pod".prev.log
  done
done
