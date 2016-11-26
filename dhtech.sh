#!/bin/bash

echo "Enter password for docker registry"
echo -n "Username: "
read username
echo -n "Password: "
read password

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
kubectl apply -f svc-bgp/svc-bgp.yaml

kubectl create namespace public
kubectl create namespace prod

kubectl replace -f svc/kube-dns.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/release-1.2/deploy/kube-config/standalone/heapster-controller.yaml
kubectl apply -f svc/heapster.yaml

kubectl apply -f https://rawgit.com/kubernetes/dashboard/master/src/deploy/kubernetes-dashboard.yaml
kubectl replace -f svc/kubernetes-dashboard.yaml
