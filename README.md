# kafka-kubernetes

## What is this?

Run kafka locally on your machine inside kubernetes. The same concept can be used to run in a production enviroment, but to do 
this, the replicas need to be > 1.

***Tldr; This can be used as a reference for a production running kafka-inside-kubernetes deployment.***

- Contains Zookeeper manifest (because kafka requires Zookeeper)
- Contains Kafka manifest
- Complete step-by-step and how to verify installation

## Locally

For running kubernetes locally and getting the `kubectl` utlity, you have at least two choices:

- microk8s: Great for ubuntu/debian based: Install https://microk8s.io/docs/ 🐧
- minikube: https://kubernetes.io/docs/tasks/tools/install-minikube/ ⚙️
- Otherwise, use a cloud kubernetes provider (Google Cloud, OpenShift etc) 💰

## 1. Start Zookeeper

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

### Verify Zookeeper 

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

## 2. Start Kafka

```
kubectl apply -f kafka-no-anti-affinity.yaml
kubectl get -w pods # wait for kafka-0 to be READY 1/1 (then Ctrl+C to stop watching)
```

### Verify Kafka 

To verify it's working, we are going to:

- Create a topic on kafka-0 called `test`
- Listen for messages on that topic using `kafka-console-consumer.sh`
- Send a message (`hello`) to the topic called `test` using `kafka-console-producer.sh`
- Verify we see the message read from the topic

First create a topic on the kafka service to verify it's working:

```
kubectl exec -it kafka-0 -- bash # exec into Kafa 0
kafka-topics.sh --create --topic test --zookeeper zk-0.zk-svc.default.svc.cluster.local:2181 --partitions 1 --replication-factor 1 # create topic
```
Expected output:
```
Created topic "test".
```
Note that we have **no** replication here because we only have a minimal one-node instance for locall testing. See `kafka.yaml` for a redundant prod deployment example.

#### Listen for topics on the `test` topic
Register a consumer to listen for messages sent to the `test` topic:

```
kubectl exec -it kafka-0 -- bash # exec into Kafa 0 # exec into kafka-0 if not already there
kafka-console-consumer.sh --topic test --bootstrap-server localhost:9093 #listen for messages # Keep terminal open
```

Finally in yet *another* terminal, send a message to the topic:

```
kubectl exec -it kafka-0 -- bash # exec into Kafa 0
kafka-console-producer.sh --topic test --broker-list localhost:9093
hello #Write 'hello' or any message you want
```

On yout consumer terminal, the expected output:
```
hello
```
Every message you type and press <Enter> to the producer, will appear on the consumer. See Help/Debugging fun if that's not happening. 

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
Delete the entire deployment **careful**. 

```
./delete-zookeeper.sh # Removes zookeeper
./delete-kafka.sh # Removes kafka
```
Note, deleting persistant data must be done manually (for your own safety!). 
e.g:
```
kubectl get pv # list persistant volumes
kubectl delete pv <pv name>
```
Note you can't delete a persistant volume if there are claims against it. To see 
those: 
```
kubectl get pvc # list persistant volume claims
kubectl delete pvc <name> # delete a persistant volume claim
```
