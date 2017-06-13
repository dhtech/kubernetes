#!/bin/bash

echo "Enter password for docker registry"
echo -n "Username: "
read username
echo -n "Password: "
read password

kubectl create namespace public
kubectl create namespace prod

for ns in $(kubectl get namespace -o name | cut -f 2 -d '/')
do
  echo "Registering pull secret for namespace $ns"
  kubectl create secret docker-registry tech-registry-key \
    --docker-server=val.tech.dreamhack.se \
    --docker-username="${username}" \
    --docker-password="${password}" \
    --docker-email=services@tech.dreamhack.se \
    --namespace="$ns"
done

kubectl apply -f calico/calico.yaml
kubectl create -f svc/kube-dns.yaml
kubectl create -f svc/heapster.yaml
kubectl create -f svc/kubernetes-dashboard.yaml
