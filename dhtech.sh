#!/bin/bash

echo "Enter password for docker registry"
echo -n "Username: "
read username
echo -n "Password: "
read password

kubectl create secret docker-registry tech-registry-key \
  --docker-server=val.tech.dreamhack.se \
  --docker-username="${username}" \
  --docker-password="${password}" \
  --docker-email=services@tech.dreamhack.se
kubectl apply -f calico/calico.yaml
kubectl apply -f svc-bgp/svc-bgp.yaml

kubectl create namespace public
kubectl create namespace prod

kubectl replace -f svc/kube-dns.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/release-1.2/deploy/kube-config/standalone/heapster-controller.yaml
kubectl apply -f svc/heapster.yaml

kubectl apply -f https://rawgit.com/kubernetes/dashboard/master/src/deploy/kubernetes-dashboard.yaml
kubectl replace -f svc/kubernetes-dashboard.yaml
