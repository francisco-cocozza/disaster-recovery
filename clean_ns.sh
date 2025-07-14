#!/usr/bin/env bash

## This script is used to clean up the namespace by removing finalizers from various resources
## It is used to prepare a cluster to be the failover cluster of a Runtime 
## It ensures there are no leftovers from previous installations
NAMESPACE=runtime-alpha

helm uninstall cf-gitops-runtime --namespace $NAMESPACE --no-hooks

kubectl patch EventBus -n $NAMESPACE $(kubectl get eventbus -n $NAMESPACE -l codefresh.io/internal=true | awk 'NR>1{print $1}' | xargs) -p '{"metadata":{"finalizers":null}}' --type=merge
kubectl patch Eventsource -n $NAMESPACE $(kubectl get EventSource -n $NAMESPACE -l codefresh.io/internal=true | awk 'NR>1{print $1}' | xargs) -p '{"metadata":{"finalizers":null}}' --type=merge 
kubectl patch Sensor -n $NAMESPACE $(kubectl get Sensor -n $NAMESPACE -l codefresh.io/internal=true | awk 'NR>1{print $1}' | xargs) -p '{"metadata":{"finalizers":null}}' --type=merge


kubectl get appprojects -n ${NAMESPACE} -o json | jq -r '.items[] | .metadata.name' | while read -r name; do
    kubectl patch -n ${NAMESPACE} appproject "$name" --type=merge -p '{"metadata":{"finalizers":[]}}'
done

kubectl get applications -n ${NAMESPACE} -o json | jq -r '.items[] | .metadata.name' | while read -r name; do
    kubectl patch -n ${NAMESPACE} applications "$name" --type=merge -p '{"metadata":{"finalizers":[]}}'
done

kubectl get secrets -n ${NAMESPACE} -o json | jq -r '.items[] | .metadata.name' | while read -r name; do
    kubectl patch -n ${NAMESPACE} secrets "$name" --type=merge -p '{"metadata":{"finalizers":[]}}'
done


kubectl get crds -o json | jq -r '.items[] | select(.spec.group == "argoproj.io") | .metadata.name' | xargs kubectl delete crd
kubectl get crds -o json | jq -r '.items[] | select(.spec.group == "codefresh.io") | .metadata.name' | xargs kubectl delete crd
kubectl get crds -o json | jq -r '.items[] | select(.spec.group == "bitnami.com") | .metadata.name' | xargs kubectl delete crd

kubectl delete ns ${NAMESPACE} 

kubectl create ns ${NAMESPACE}