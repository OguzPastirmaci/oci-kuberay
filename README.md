# Ray Operator on OKE

### Deploy an OKE cluster
You can follow the instructions [here](https://www.oracle.com/webfolder/technetwork/tutorials/obe/oci/oke-full/index.html) for deploying an OKE cluster.

You will need a CPU worker pool and a GPU worker pool. Any GPU shape will work, but this readme uses A10 VMs and BMs.

To test if everything works as expected, run `kubectl get nodes`. You should have a similar output (the number of nodes and the information might be different):

```
kubectl get nodes

NAME          STATUS   ROLES   AGE   VERSION
10.0.10.135   Ready    node    19h   v1.25.4
10.0.10.18    Ready    node    19h   v1.25.4
10.0.10.180   Ready    node    19h   v1.25.4
10.0.10.240   Ready    node    19h   v1.25.4
10.0.10.247   Ready    node    19h   v1.25.4
10.0.10.37    Ready    node    19h   v1.25.4
10.0.10.5     Ready    node    19h   v1.25.4
10.0.10.57    Ready    node    19h   v1.25.4
10.0.10.95    Ready    node    19h   v1.25.4
```

### Install Helm
Install Helm using the instructions [here](https://helm.sh/docs/intro/install/).

### Install Ray
Install Ray in your local machine using the instructions [here](https://docs.ray.io/en/latest/ray-overview/installation.html) if you want to try submitting jobs to your Ray cluster from your machine.

### Deploy the KubeRay Operator

```
helm repo add kuberay https://ray-project.github.io/kuberay-helm/
helm repo update

helm install kuberay-operator kuberay/kuberay-operator --version 1.0.0-rc.0
```

1 - Run the following commands to deploy a new cluster:

For A10 Bare Metal instances
```
kubectl apply -f https://raw.githubusercontent.com/OguzPastirmaci/oci-kuberay/main/raycluster-autoscaler-oke-a10-bm.yaml
```

For A10 Virtual Machine instances
```
kubectl apply -f https://raw.githubusercontent.com/OguzPastirmaci/oci-kuberay/main/raycluster-autoscaler-oke-a10-vm.yaml
```
2 - Check that you see at least 1 head pod and 1 worker pod.

```
kubectl get pods --selector=ray.io/cluster=raycluster-autoscaler
```

```
NAME                                                   READY   STATUS    RESTARTS   AGE
raycluster-autoscaler-head-gcvcr                       2/2     Running   0          127m
raycluster-autoscaler-worker-ray-worker-a10-bm-lmnph   1/1     Running   0          127m
```

### Running Ray jobs in the cluster

#### Method 1: Submit a Ray job to the RayCluster via ray job submission SDK

1 - Run this command in a separate shell and keep it open. This command might fail when it's idle for a while. You can run it again.

```
kubectl port-forward --address 0.0.0.0 service/raycluster-autoscaler-head-svc 8265:8265
```

2 - After running the `kubectl port-forward` command in the previous step, you should be able to open your browser and access the GUI of the Ray Dashboard by going to http://localhost:8265

3 - Now let's submit a test Ray job to the cluster. We need to set the `RAY_ADDRESS` environment variable so our local Ray client knows where the head node is.

```
ray job submit --address http://localhost:8265 -- python -c "import ray; ray.init(); print(ray.cluster_resources())"
```

You should see an output similar to:

```
...
2023-03-01 16:31:03,670 INFO worker.py:1231 -- Using address 10.244.2.132:6379 set in the environment variable RAY_ADDRESS
2023-03-01 16:31:03,671 INFO worker.py:1352 -- Connecting to existing Ray cluster at address: 10.244.2.132:6379...
2023-03-01 16:31:03,677 INFO worker.py:1535 -- Connected to Ray cluster. View the dashboard at http://10.244.2.132:8265 
{'object_store_memory': 217329965465.0, 'GPU': 4.0, 'node:10.244.3.2': 1.0, 'CPU': 134.0, 'memory': 1078036791296.0, 'accelerator_type:A10': 1.0, 'node:10.244.2.132': 1.0}
...
```

4 - You can also submit a job to run your python script directly. You can find an example in this repo (https://github.com/OguzPastirmaci/oci-kuberay/blob/main/examples/gpu.py)

```
ray job submit --address http://localhost:8265 --working-dir <working directory> --no-wait -- python gpu.py
```

#### Method 2: Execute a Ray job in the head Pod

```
export HEAD_POD=$(kubectl get pods --selector=ray.io/node-type=head -o custom-columns=POD:metadata.name --no-headers)

# Print the cluster resources.
kubectl exec -it $HEAD_POD -- python -c "import ray; ray.init(); print(ray.cluster_resources())"
```

## Removing/redeploying the Ray Cluster if needed
You can follow the below steps if you want to redeploy the Ray cluster on Kubernetes.

You can edit/use the Kubernetes deployment yaml file here: https://github.com/OguzPastirmaci/oci-kuberay/blob/main/raycluster-autoscaler-oke.yaml

### Removing the current cluster

1 - Run the following command to remove the current cluster:

For A10 Bare Metal instances
```
kubectl delete -f https://raw.githubusercontent.com/OguzPastirmaci/oci-kuberay/main/raycluster-autoscaler-oke-a10-bm.yaml
```

For A10 Virtual Machine instances
```
kubectl delete -f https://raw.githubusercontent.com/OguzPastirmaci/oci-kuberay/main/raycluster-autoscaler-oke-a10-vm.yaml
```

2 - Check that you don't see any Ray pods listed by running the following command:

```
kubectl get pods --selector=ray.io/cluster=raycluster-autoscaler
```
