# Deploying Ray Operator on OKE

### Deploying the KubeRay operator

1 - Deploy the KubeRay Operator with the following command:

```
kubectl create -k "github.com/ray-project/kuberay/ray-operator/config/default?ref=v0.3.0&timeout=90s"
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
