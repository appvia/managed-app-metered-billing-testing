#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
${TRACE:+set -x}

MRG=${1:-${MRG?Must provide a resource group name}}
IDENTITY_NAME=${2:-${IDENTITY_NAME?Must provide an identity name}}
SUBSCRIPTION=$(az account show --query id -o tsv)
CLIENT_ID=$(az identity show --name $IDENTITY_NAME --resource-group $MRG --query clientId -o tsv)
IDENTITY_NAME_LC=${IDENTITY_NAME,,}


cat <<EOF >AzureIdentity.yaml
apiVersion: "aadpodidentity.k8s.io/v1"
kind: AzureIdentity
metadata:
  name: ${IDENTITY_NAME_LC}
spec:
  type: 0
  resourceID: /subscriptions/${SUBSCRIPTION}/resourcegroups/${MRG}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${IDENTITY_NAME}
  clientID: ${CLIENT_ID}
---
apiVersion: "aadpodidentity.k8s.io/v1"
kind: AzureIdentityBinding
metadata:
  name: ${IDENTITY_NAME_LC}-binding
spec:
  azureIdentity: ${IDENTITY_NAME_LC}
  selector: ${IDENTITY_NAME_LC}
EOF

kubectl apply -f AzureIdentity.yaml

echo "Now run the following to test the identity in a pod:
  kubectl run --rm -it testpodidentity --image=alpine --labels=\"aadpodidbinding=${IDENTITY_NAME}\""
