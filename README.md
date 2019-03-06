# kafka-kubernetes

## Locally

### 1 Start Zookeeper

If you run on a single node (e.g. locally; **don't** do this in production) with replicas > 1 then your deployment will fail. Why? Because your zookeeper pods won't be able to bind to their listen port (2181) because it'll already be in use. 

To fudge this locally, you may use `zookeeper-no-anti-afinity-no-fault-tolerance.yaml` which turns of affinity rules and reduces replicas down to 1.

Do not use in production. Provides no fault tolerance:
```
  kubectl apply -f zookeeper-no-anti-afinity-no-fault-tolerance.yaml
```

### 2 Start Kafka


## Debugging fun

See / monitor pod creation after issuing `kubectl apply -f`:
```
kubectl get -w pods -l app=zk # The -l means only show pods with the label app and equal to zk
```

If a pod creation is failing (e.g. crashloop back off) then look deeper:
```
kubectl describe pod <pod name>
```
And/or look at it's logs, if it's alive
```
kubectl logs -f <pod name>

```

Based on src: 
- https://github.com/kubernetes/contrib/tree/master/statefulsets/zookeeper 
- https://github.com/kubernetes/contrib/tree/master/statefulsets/kafka
