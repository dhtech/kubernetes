#!/bin/bash

kubectl create namespace public
kubectl create namespace prod

for i in svc/*.yaml
do
  kubectl apply -f $i
done
