# scalingcloud

To setup the environment, add the secrets:
AZURE_SUBSCRIPTION_ID (need to point to an active subscription)
AZURE_RESOURCE_GROUP (will be created if it does not exist)

When they are configured, trigger the action workflow called "azure-bicep-deploy", this will setup the infrastructure for the test in the specified resource group.
As of now the resource group will be setup in the 'swedencentral' region.


to deploy the test webApp, push a change to the repository or trigger the actions workflow called "webapp-workflow".

to tare everything down, execute the command:
az group delete --name <AZURE_RESOURCE_GROUP> --subscription <AZURE_SUBSCRIPTION_ID> --yes --no-wait