#!/bin/bash
set -e

kubectl delete cluster management
clusterctl delete --all