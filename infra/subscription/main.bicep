param appName string
param environment string
param region string
param location string = resourceGroup().location
param aadUserObjectId string

module names '../resource-names.bicep' = {
  name: 'resource-names'
  params: {
    appName: appName
    region: region
    env: environment
  }
}

module eventSubscriptionDeployment 'event-subscription.bicep' = {
  name: 'event-subscription-deployment'
  params: {
    keyVaultName: names.outputs.keyVaultName
    keyVaultSecretExpiringEventGridTopicName: names.outputs.keyVaultSecretExpiringEventGridTopicName
    location: location
    logAnalyticsWorkspaceName: names.outputs.logAnalyticsWorkspaceName
    rotateKeyVaultSecretFunctionAppName: names.outputs.rotateKeyVaultSecretFunctionAppName
    rotateKeyVaultSecretFunctionEndpointName: names.outputs.rotateKeyVaultSecretFunctionEndpointName
  }
}
