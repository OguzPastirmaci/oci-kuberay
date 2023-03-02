# Deploying Ray Operator on OKE

### Deploying the KubeRay operator

1 - Deploy the KubeRay Operator with the following command:

```
kubectl create -k "github.com/ray-project/kuberay/ray-operator/config/default?ref=v0.4.0&timeout=90s""
```

2 - Confirm that the operator is running in the namespace `ray-system`.

```
kubectl -n ray-system get pod --selector=app.kubernetes.io/component=kuberay-operator

# NAME                                READY   STATUS    RESTARTS   AGE
# kuberay-operator-557c6c8bcd-t9zkz   1/1     Running   0          XXs
```

### Deploying a Ray Cluster

1 - Once the KubeRay operator is running,  we are ready to deploy a Ray cluster.

**IMPORTANT NOTE:** The configuration we used below is for the `BM.GPU.A10.4` shape. If you're using a different shape, change the `workerGroupSpecs` accordingly.

```
kubectl apply -f https://raw.githubusercontent.com/OguzPastirmaci/oci-kuberay/main/raycluster-autoscaler-oke.yaml
```

2 - The KubeRay operator will detect the RayCluster object. The operator will then start your Ray cluster by creating head and worker pods. To view Ray cluster’s pods, run the following command:

```
kubectl get pods --selector=ray.io/cluster=raycluster-autoscaler

# NAME                                             READY   STATUS    RESTARTS   AGE
# raycluster-autoscaler-head-xxxxx                 2/2     Running   0          XXs
# raycluster-autoscaler-worker-small-group-yyyyy   1/1     Running   0          XXs
```

3 - Wait for the pods to reach Running state. This may take a few minutes – most of this time is spent downloading the Ray images.

### Ray Job submission

1 - When they pods from the previous step are in Running state, use port-forwarding to access the Ray Dashboard port (8265 by default).

```
# Execute this in a separate shell.

kubectl port-forward service/raycluster-autoscaler-head-svc 8265:8265
```
2 - Let's submit a test job. The following job's logs will show the Ray cluster's total resource capacity.

```
ray job submit --address http://localhost:8265 -- python -c "import ray; ray.init(); print(ray.cluster_resources())" 

...
2023-03-01 16:31:03,670 INFO worker.py:1231 -- Using address 10.244.2.132:6379 set in the environment variable RAY_ADDRESS
2023-03-01 16:31:03,671 INFO worker.py:1352 -- Connecting to existing Ray cluster at address: 10.244.2.132:6379...
2023-03-01 16:31:03,677 INFO worker.py:1535 -- Connected to Ray cluster. View the dashboard at http://10.244.2.132:8265 
{'object_store_memory': 217329965465.0, 'GPU': 4.0, 'node:10.244.3.2': 1.0, 'CPU': 134.0, 'memory': 1078036791296.0, 'accelerator_type:A10': 1.0, 'node:10.244.2.132': 1.0}
...
```


