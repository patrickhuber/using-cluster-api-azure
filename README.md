# using-cluster-api-azure
repo to play around with clusterapi on azure

## dependencies

The devcontainer contains all the dependencies outlined here https://cluster-api.sigs.k8s.io/user/quick-start.html#install-clusterctl

## prerequisites

Follow the prerequisites here https://capz.sigs.k8s.io/topics/getting-started.html#prerequisites

## variables

See: https://cluster-api.sigs.k8s.io/clusterctl/commands/generate-cluster#variables

```bash
clusterctl generate cluster mycluster --infrastructure azure --list-variables
```

```
Required Variables:
  - AZURE_CLIENT_ID_USER_ASSIGNED_IDENTITY
  - AZURE_CONTROL_PLANE_MACHINE_TYPE
  - AZURE_LOCATION
  - AZURE_NODE_MACHINE_TYPE
  - AZURE_SUBSCRIPTION_ID
  - AZURE_TENANT_ID
  - CLUSTER_IDENTITY_NAME
  - KUBERNETES_VERSION

Optional Variables:
  - AZURE_RESOURCE_GROUP         (defaults to "${CLUSTER_NAME}")
  - AZURE_SSH_PUBLIC_KEY_B64     (defaults to "")
  - AZURE_VNET_NAME              (defaults to "${CLUSTER_NAME}-vnet")
  - CI_RG                        (defaults to "capz-ci")
  - CLUSTER_IDENTITY_TYPE        (defaults to "WorkloadIdentity")
  - CLUSTER_NAME                 (defaults to mycluster)
  - CONTROL_PLANE_MACHINE_COUNT  (defaults to 1)
  - USER_IDENTITY                (defaults to "cloud-provider-user-identity")
  - WORKER_MACHINE_COUNT         (defaults to 0)
```

## troubleshooting

### WSL2 CoreDNS issue

In wsl 2 there is an issue with coredns where it receives a buffer overflow when resolving login.microsoftonline.com. This appears to be a bug in coredns 1.10.* and it looks like 1.11.3 addresses the overflow. At the time of these tests, 1.11.* was not available to kubernetes. 

```bash
kubectl logs --namespace=kube-system -l k8s-app=kube-dns
```

```
[ERROR] plugin/errors: 2 login.microsoftonline.com. A: dns: buffer size too small
[ERROR] plugin/errors: 2 login.microsoftonline.com. A: dns: buffer size too small
[ERROR] plugin/errors: 2 login.microsoftonline.com. AAAA: dns: overflowing header size
[ERROR] plugin/errors: 2 login.microsoftonline.com. AAAA: dns: overflowing header size
[ERROR] plugin/errors: 2 login.microsoftonline.com. A: dns: buffer size too small
[ERROR] plugin/errors: 2 login.microsoftonline.com. AAAA: dns: overflowing header size
[ERROR] plugin/errors: 2 login.microsoftonline.com. A: dns: buffer size too small
```

The patch file below updates the coredns file using a config map to resolve login.microsoftonline.com to cloudflare dns 1.1.1.1

```bash
kubectl apply -f coredns.yml
```

### Azure Clusterapi Provider Troubleshooting

https://capz.sigs.k8s.io/self-managed/troubleshooting

```bash
kubectl logs deploy/capz-controller-manager -n capz-system manager > capz-system-manager.log
```

#### Logs contain 'failed to init machine scope cache: failed to get default image: no VM image found for publisher "cncf-upstream" offer "capi" sku "ubuntu-2204-gen1" with Kubernetes version "v1.31.0\"'

```bash
az vm image list -p "cncf-upstream" -f "capi" -s "ubuntu-2204-gen1" --all
```

Verify the image is listed in the output. There will probably be several. 

Grab the one with the highest version number, for example:

```json
{
    "architecture": "x64",
    "imageDeprecationStatus": {
      "imageState": "Active",
      "scheduledDeprecationTime": null
    },
    "offer": "capi",
    "publisher": "cncf-upstream",
    "sku": "ubuntu-2204-gen1",
    "urn": "cncf-upstream:capi:ubuntu-2204-gen1:130.3.20240717",
    "version": "130.3.20240717"
}
```

The version number here is the maximum supported kubernetes version by capz, in this case "130.3.20240717" is Kubernetes version "1.30.3" due to the formatting search applied here: https://github.com/kubernetes-sigs/cluster-api-provider-azure/blob/0f48c52736a7baee690fba702e96f31711f2cfef/azure/services/virtualmachineimages/images.go#L170C20-L170C30 . A the time of writing this, I believe there is an effort to migrate away from marketplace images to shared image gallieries. 