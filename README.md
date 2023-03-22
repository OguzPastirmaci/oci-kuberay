# Ray Operator on OKE

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

4 - Run the following commands to setup the access info for the Kubernetes cluster.

```
mkdir -p $HOME/.kube

oci ce cluster create-kubeconfig --cluster-id ocid1.cluster.oc1.iad.aaaaaaaaiwvmnv64tqs45ycsyk5kvuyvkcbepttniqjhmkd4ycngl6n5z7mq --file $HOME/.kube/config --region us-ashburn-1 --token-version 2.0.0  --kube-endpoint PUBLIC_ENDPOINT

export KUBECONFIG=$HOME/.kube/config
```

5 - To test if everything works as expected, run `kubectl get nodes`. You should have a similar output (the number of nodes and the information might be different):

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

```
kubectl delete -f https://raw.githubusercontent.com/OguzPastirmaci/oci-kuberay/main/raycluster-autoscaler-oke.yaml
```

2 - Check that you don't see any Ray pods listed by running the following command:

```
kubectl get pods --selector=ray.io/cluster=raycluster-autoscaler
```

### Deploying a new cluster

1 - Run the following command to deploy a new cluster:

```
kubectl apply -f https://raw.githubusercontent.com/OguzPastirmaci/oci-kuberay/main/raycluster-autoscaler-oke.yaml
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

### Creating a new node pool with A10 VMs (VM.GPU.A10.1)
Save the following script as `extend-boot-volume.yaml`.

```
#!/bin/bash

curl --fail -H "Authorization: Bearer Oracle" -L0 http://169.254.169.254/opc/v2/instance/metadata/oke_init_script | base64 --decode >/var/run/oke-init.sh

bash /var/run/oke-init.sh

sudo dd iflag=direct if=/dev/oracleoci/oraclevda of=/dev/null count=1
echo "1" | sudo tee /sys/class/block/`readlink /dev/oracleoci/oraclevda | cut -d'/' -f 2`/device/rescan

sudo /usr/libexec/oci-growfs -y
```

Change the values for `NODE_POOL_NAME`, `NODE_POOL_SIZE`, `NODE_POOL_BOOT_VOLUME_SIZE_IN_GB`,and `NODE_IMAGE_ID` and run the below command. The last line in the command will run the above script with cloud-init.


```sh
NODE_POOL_NAME=
NODE_POOL_SIZE=
NODE_POOL_BOOT_VOLUME_SIZE_IN_GB=
NODE_IMAGE_ID=

oci ce node-pool create \
--cluster-id ocid1.cluster.oc1.iad.aaaaaaaaiwvmnv64tqs45ycsyk5kvuyvkcbepttniqjhmkd4ycngl6n5z7mq \
--compartment-id ocid1.compartment.oc1..aaaaaaaaetnugzyxgxghutf53ijzebb3ouvdpzyndpr552ffpfvp4oq7lera \
--kubernetes-version v1.25.4 \
--name $NODE_POOL_NAME \
--node-shape VM.GPU.A10.1 \
--node-image-id $NODE_IMAGE_ID \
--node-boot-volume-size-in-gbs $NODE_POOL_BOOT_VOLUME_SIZE_IN_GB \
--size $NODE_POOL_SIZE \
--placement-configs '[{"availabilityDomain": "'XDxy:US-ASHBURN-AD-1'", "subnetId": "'ocid1.subnet.oc1.iad.aaaaaaaagde6cv3pbgrc25au3phms7jbe5jchcrtprxqgfnxb4uvqv3k5dlq'"}]' \
--node-metadata '{"user_data": "$(cat extend-boot-volume.yaml | base64)"}'
```

