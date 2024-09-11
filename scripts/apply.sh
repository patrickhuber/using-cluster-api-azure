#!/bin/bash
set -e
dir=$(dirname "$0")
root=$(realpath $dir "..")

# check for required variables
[[ -z "${AZURE_SUBSCRIPTION_ID}" ]] && echo "Missing AZURE_SUBSCRIPTION_ID environment variable" && exit 1
[[ -z "${AZURE_TENANT_ID}" ]] && echo "Missing AZURE_TENANT_ID environment variable" && exit 1
[[ -z "${AZURE_CLIENT_ID}" ]] && echo "Missing AZURE_CLIENT_ID environment variable" && exit 1
[[ -z "${AZURE_CLIENT_SECRET}" ]] && echo "Missing AZURE_CLIENT_SECRET environment variable" && exit 1

# Base64 encode the variables
export AZURE_SUBSCRIPTION_ID_B64="$(echo -n "$AZURE_SUBSCRIPTION_ID" | base64 | tr -d '\n')"
export AZURE_TENANT_ID_B64="$(echo -n "$AZURE_TENANT_ID" | base64 | tr -d '\n')"
export AZURE_CLIENT_ID_B64="$(echo -n "$AZURE_CLIENT_ID" | base64 | tr -d '\n')"
export AZURE_CLIENT_SECRET_B64="$(echo -n "$AZURE_CLIENT_SECRET" | base64 | tr -d '\n')"

# Settings needed for AzureClusterIdentity used by the AzureCluster
export AZURE_CLUSTER_IDENTITY_SECRET_NAME="cluster-identity-secret"
export CLUSTER_IDENTITY_NAME="cluster-identity"
export AZURE_CLUSTER_IDENTITY_SECRET_NAMESPACE="default"
export EXP_MACHINE_POOL=true

# Create a secret to include the password of the Service Principal identity created in Azure
# This secret will be referenced by the AzureClusterIdentity used by the AzureCluster
kubectl create secret generic "${AZURE_CLUSTER_IDENTITY_SECRET_NAME}" \
  --from-literal=clientSecret="${AZURE_CLIENT_SECRET}" \
  --namespace "${AZURE_CLUSTER_IDENTITY_SECRET_NAMESPACE}" \
  --dry-run=client -o yaml \
  | kubectl apply -f -

# patch coredns
kubectl apply -f coredns.yml

# Finally, initialize the management cluster
clusterctl init --infrastructure azure

# Name of the Azure datacenter location. Change this value to your desired location.
export AZURE_LOCATION="eastus2"

# Select VM types.
export AZURE_CONTROL_PLANE_MACHINE_TYPE="Standard_B2s"
export AZURE_NODE_MACHINE_TYPE="Standard_B2s"

# [Optional] Select resource group. The default value is ${CLUSTER_NAME}.
export AZURE_RESOURCE_GROUP="foundation"

# generate configuration
# make sure quickstart-cluster.yml is in the .gitignore
clusterctl generate cluster management \
  --infrastructure azure \
  --kubernetes-version v1.30.1 \
  --flavor machinepool \
  --control-plane-machine-count 1 \
  --worker-machine-count 1 > quickstart-cluster.yml

# Wait for CAPZ deployments
echo "Waiting for CAPZ deployment to be Available..."
kubectl wait --for=condition=Available --timeout=5m -n capz-system deployment --all

kubectl apply -f quickstart-cluster.yml

# Wait for management cluster to be Available
kubectl wait --for=condition=Ready --timeout=5m kubeadmcontrolplane
