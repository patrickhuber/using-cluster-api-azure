# using-cluster-api-azure
repo to play around with clusterapi on azure

## dependencies

The devcontainer contains all the dependencies outlined here https://cluster-api.sigs.k8s.io/user/quick-start.html#install-clusterctl

## prerequisites

Follow the prerequisites here https://capz.sigs.k8s.io/topics/getting-started.html#prerequisites

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