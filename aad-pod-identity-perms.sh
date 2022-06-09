#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
${TRACE:+set -x}

SUBSCRIPTION=$(az account show --query id -o tsv)
MRG=${1:-${MRG?Must provide a resource group name}}
CLUSTER_NAME=${2:-${CLUSTER_NAME?Must provide a cluster name}}
AKS_IDENTITY_ID=$(az aks show -g ${MRG} -n ${CLUSTER_NAME} --query identityProfile.kubeletidentity.objectId -otsv)
NODE_RG=$(az aks show -g ${MRG} -n ${CLUSTER_NAME} --query nodeResourceGroup -otsv)

function ensure_role_assingment() {
    local name=${1:-?Must provide a role name}
    local subscription=${2:-?Must provide a subscription id}
    local assignee=${3:-?Must provide an assignee}
    local scope=${4:-?Must provide a scope}

    if az role assignment list --assignee ${assignee} --role "${name}" --scope ${scope} | jq -r .[].scope | grep "${scope}" >/dev/null ; then
        echo "${name} role assingment exists"
    else
        echo "${name} role assingment does not exist, creating"
        az role assignment create --role "${name}" --assignee ${assignee} --scope ${scope} >/dev/null
    fi
}

function install_aad_pod_identity() {
    echo "Ensuring helm chart is installed"
    helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts
    helm -n kube-system install aad-pod-identity aad-pod-identity/aad-pod-identity
}

# Create a role assignment for the kubelet service principal
# See https://azure.github.io/aad-pod-identity/docs/getting-started/role-assignment/#performing-role-assignments
ensure_role_assingment "Managed Identity Operator" ${SUBSCRIPTION} ${AKS_IDENTITY_ID} "/subscriptions/${SUBSCRIPTION}/resourcegroups/${NODE_RG}"
ensure_role_assingment "Virtual Machine Contributor" ${SUBSCRIPTION} ${AKS_IDENTITY_ID} "/subscriptions/${SUBSCRIPTION}/resourcegroups/${NODE_RG}"

# Allow the kubelete identity to access the managed identities we will use
# See https://azure.github.io/aad-pod-identity/docs/getting-started/role-assignment/#user-assigned-identities-that-are-not-within-the-node-resource-group
ensure_role_assingment "Managed Identity Operator" ${SUBSCRIPTION} ${AKS_IDENTITY_ID} "/subscriptions/${SUBSCRIPTION}/resourcegroups/${MRG}"

# If we need to specifically limit which identities the cluster can use, we can do that here.
#ensure_role_assingment "Managed Identity Operator" ${SUBSCRIPTION} ${AKS_IDENTITY_ID} "/subscriptions/<SubscriptionID>/resourcegroups/<IdentityResourceGroup>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<IdentityName>"

install_aad_pod_identity

