#! /usr/bin/env bash
kubectl delete PodDisruptionBudgets kafka-pdb
kubectl delete service kafka-svc
kubectl delete statefulSet kafka
kubectl delete service kafka-svc
kubectl delete pvc datadir-kafka-0 
