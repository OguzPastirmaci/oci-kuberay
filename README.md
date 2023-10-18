# Ray Operator on OKE

### Deploying an OKE cluster
You can follow the instructions [here](https://www.oracle.com/webfolder/technetwork/tutorials/obe/oci/oke-full/index.html) for deploying an OKE cluster.

### Installing kubectl

The Kubernetes command-line tool, kubectl, allows you to run commands against Kubernetes clusters.

Please follow the instructions in https://kubernetes.io/docs/tasks/tools/ to install `kubectl` based on your operating system.

### Installing OCI CLI

1 - Follow the instruction in https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm for installing the CLI.

2 - Save the private key in the email to a location in your computer. We will use the location of the private key in the next step.

3 - Copy the content in the email to `~/.oci/config`.

The content will look like below (redacted version):

```
[DEFAULT]
user=ocid1.user.oc1..aaaaaaaa7cupiq3r52
fingerprint=21:bb:c2:09:d2:97
tenancy=ocid1.tenancy.oc1..aaaaaaaae
region=us-ashburn-1
key_file=<path to your private keyfile> # TODO
```

Make sure to change the `key_file` to the location of the private key.

4 - To test if everything works as expected, run `kubectl get nodes`. You should have a similar output (the number of nodes and the information might be different):

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

6 - Now your access to the Kubernetes cluster is done. You won't need to follow the above steps again.


### Deploying a new Ray cluster

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

### Submitting Ray jobs to the cluster

Now let's submit a test job to the Ray cluster. First we need to run the port-forward command to create a connection between your computer and the Ray cluster running on Kubernetes.

1 - Run this command in a separate shell and keep it open. This command might fail when it's idle for a while. You can run it again.

```
kubectl port-forward service/raycluster-autoscaler-head-svc 8265:8265
```

2 - After running the `kubectl port-forward` command in the previous step, you should be able to open your browser and access the GUI of the Ray Dashbord by going to http://localhost:8265

3 - Now let's submit a test Ray job to the cluster. We need to set the `RAY_ADDRESS` environment variable so our local Ray client knows where the head node is.

```
export RAY_ADDRESS="http://127.0.0.1:8265"
```

```
ray job submit -- python -c "import ray; ray.init(); print(ray.cluster_resources())" 
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
ray job submit --working-dir <working directory> --no-wait -- python gpu.py
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
