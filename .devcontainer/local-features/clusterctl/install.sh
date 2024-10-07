#!/usr/bin/env bash
set -e
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.8.3/clusterctl-linux-amd64 -o clusterctl
chmod +x clusterctl
cp clusterctl /usr/local/bin
rm clusterctl