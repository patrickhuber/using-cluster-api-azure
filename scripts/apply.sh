#!/bin/bash
set -e
dir=$(dirname "$0")
root=$(realpath $dir "..")

# check for required variables
[[ -z "${AZURE_TENANT_ID}" ]] && echo "Missing AZURE_TENANT_ID environment variable" && exit 1
[[ -z "${AZURE_SUBSCRIPTION_ID}" ]] && echo "Missing AZURE_SUBSCRIPTION_ID environment variable" && exit 1
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
clusterctl init --infrastructure azure --wait-providers

# Name of the Azure datacenter location. Change this value to your desired location.
export AZURE_LOCATION="eastus2"

# Select VM types.
export AZURE_CONTROL_PLANE_MACHINE_TYPE="Standard_B2s"
export AZURE_NODE_MACHINE_TYPE="Standard_B2s"

# [Optional] Select resource group. The default value is ${CLUSTER_NAME}.
export AZURE_RESOURCE_GROUP="management"

export CLUSTER_NAME="management"

# generate configuration
# make sure quickstart-cluster.yml is in the .gitignore
clusterctl generate cluster ${CLUSTER_NAME} \
  --infrastructure azure \
  --kubernetes-version v1.30.3 \
  --flavor machinepool \
  --control-plane-machine-count 1 \
  --worker-machine-count 1 > quickstart-cluster.yml

echo "change authentication to ServicePrincipal"
yq -i "with(. | select(.kind == \"AzureClusterIdentity\"); .spec.type |= \"ServicePrincipal\" | .spec.clientSecret.name |= \"${AZURE_CLUSTER_IDENTITY_SECRET_NAME}\" | .spec.clientSecret.namespace |= \"${AZURE_CLUSTER_IDENTITY_SECRET_NAMESPACE}\")" quickstart-cluster.yml
yq -i "with(. | select(.kind == \"AzureMachineTemplate\"); del(.spec.template.spec.identity) | del(.spec.template.spec.userAssignedIdentities))" quickstart-cluster.yml

# Wait for CAPZ deployments
echo "Waiting for CAPZ deployment to be Available..."
kubectl wait --for=condition=Available --timeout=1h -n capz-system deployment --all

kubectl apply -f quickstart-cluster.yml

# Wait for management cluster to be Available
echo "Waiting for Cluster to be Ready..."
kubectl wait --for=condition=InfrastructureReady --timeout=1h cluster ${CLUSTER_NAME}

# fetch the workload cluster kubeconfig
export WORKLOAD_KUBECONFIG="capi-quickstart.kubeconfig"
echo "Fetch the workload cluster kubeconfig"
for retries in {1..5};
do 
  clusterctl get kubeconfig ${CLUSTER_NAME} > ${WORKLOAD_KUBECONFIG} && break || sleep 60;  
  echo "'clusterctl get kubeconfig' Command failed, retrying ${retries}"
done

# install cloud provider
echo "Install Azure Cloud Provider in workload cluster"
for retries in {1..5};
do
  helm install --kubeconfig=./${WORKLOAD_KUBECONFIG} --repo https://raw.githubusercontent.com/kubernetes-sigs/cloud-provider-azure/master/helm/repo cloud-provider-azure --generate-name --set infra.clusterName=capi-quickstart --set cloudControllerManager.clusterCIDR="192.168.0.0/16"
  echo "'helm install' command failed, retrying ${retries}"
done

# install calico CNI
echo "Install Calico CNI in workload cluster"
helm repo add projectcalico https://docs.tigera.io/calico/charts --kubeconfig=./${WORKLOAD_KUBECONFIG} && \
helm install calico projectcalico/tigera-operator --kubeconfig=./${WORKLOAD_KUBECONFIG} -f https://raw.githubusercontent.com/kubernetes-sigs/cluster-api-provider-azure/main/templates/addons/calico/values.yaml --namespace tigera-operator --create-namespace
kubectl --kubeconfig=./${WORKLOAD_KUBECONFIG} get nodes
