# managed-app-metered-billing-testing

## Bash script to exercise the metered billing API for Microsoft marketplace managed applications

Essentially a bash conversion of the PowerShell scripts at [Marketplace metering service authentication strategies](https://docs.microsoft.com/en-us/azure/marketplace/marketplace-metering-service-authentication)

## Scripts to configure an AzureIdentity with managed Identity in the MRG

`aad-pod-identity-perms.sh` - add perms to MRG identity and deploy AAD Pod Identity
`createidentities.sh` - deploy identity to working AKS with AAD-Pod Identity

