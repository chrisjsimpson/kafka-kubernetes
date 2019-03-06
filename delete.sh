#! /usr/bin/env bash
kubectl delete statefulset zk
kubectl delete service zk-cs zk-hs
kubectl delete configmap zk-cm
kubectl delete pvc datadir-zk-0
