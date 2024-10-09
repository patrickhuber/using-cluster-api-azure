#!/usr/bin/env bash
set -e
export VERSION="1.8.4"
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v${VERSION}/clusterctl-linux-amd64 -o clusterctl
chmod +x clusterctl
cp clusterctl /usr/local/bin
rm clusterctl