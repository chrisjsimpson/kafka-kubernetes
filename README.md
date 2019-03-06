# kafka-kubernetes

## Locally

### Start Zookeeper

If you run on a single node (e.g. locally; **don't** do this in production) with replicas > 1 then your deployment will fail. Why? Because your zookeeper pods won't be able to bind to their listen port (2181) because it'll already be in use. 

To fudge this locally, you may use `zookeeper-no-anti-afinity-no-fault-tolerance.yaml` which turns of affinity rules and reduces replicas down to 1.

Do not use in production. Provides no fault tolerance:
```
kubectl apply -f zookeeper-no-anti-afinity-no-fault-tolerance.yaml
```

Watch/monitor pod creation as it happens:

```
kubectl get -w pods -l app=zk # The -l means only show pods with the label app and equal to zk

```
You should see:
```
NAME   READY   STATUS              RESTARTS   AGE
zk-0   0/1     ContainerCreating   0          36h
zk-0   0/1   Running   0     36h
zk-0   1/1   Running   0     36h
```
If not see debugging & help below.

### Verify

Put an object in zookeeper and then get it back out to verify:

```
kubectl exec zk-0 zkCli.sh create /hello world
```
Output should include: `Created /hello`

Get the object back out:

```
kubectl exec zk-0 zkCli.sh get /hello
```
Output should include: `world` and `dataLength = 5`
**Note:** This isn't testing replication if your replicas are set to 1, also
to properly test, put an object in instance `zk-0` and then try to `GET` it from
`zk-1` or `zk-2` to verify.

### 2 Start Kafka


#### Debugging fun


If a pod creation is failing (e.g. crashloop back off) then look deeper:
```
kubectl describe pod <pod name>
```
And/or look at it's logs, if it's alive
```
kubectl logs -f <pod name>

```

#### Help

- My pod is still in 'pending' state, why?
    - try `kubectl describe pod <pod name>` to see why
    - You might want to fix (e.g. memory requirements on local machine), delete the pod (`kubectl delete pod <pod-name>`), and try again 

Based on src: 
- https://github.com/kubernetes/contrib/tree/master/statefulsets/zookeeper 
- https://github.com/kubernetes/contrib/tree/master/statefulsets/kafka

## Uninstall / Remove / Delete
Delete the entire deployment, including persistant data. **careful**

```
./delete.sh
```
