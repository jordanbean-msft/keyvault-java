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

module managedIdentityDeployment 'managed-identity.bicep' = {
  name: 'managed-identity-deployment'
  params: {
    location: location
    managedIdentityName: names.outputs.managedIdentityName
  }
}

module loggingDeployment 'logging.bicep' = {
  name: 'logging-deployment'
  params: {
    logAnalyticsWorkspaceName: names.outputs.logAnalyticsWorkspaceName
    location: location
    appInsightsName: names.outputs.appInsightsName
    rotateKeyVaultSecretFunctionAppName: names.outputs.rotateKeyVaultSecretFunctionAppName
  }
}

module keyVaultDeployment 'key-vault.bicep' = {
  name: 'key-vault-deployment'
  params: {
    keyVaultName: names.outputs.keyVaultName
    location: location
    logAnalyticsWorkspaceName: loggingDeployment.outputs.logAnalyticsWorkspaceName
    managedIdentityName: managedIdentityDeployment.outputs.managedIdentityName
    aadUserObjectId: aadUserObjectId
  }
}

module storageDeployment 'storage.bicep' = {
  name: 'storage-deployment'
  params: {
    location: location
    logAnalyticsWorkspaceName: loggingDeployment.outputs.logAnalyticsWorkspaceName
    storageAccountName: names.outputs.storageAccountName
  }
}

module functionAppDeployment 'function-app.bicep' = {
  name: 'function-app-deployment'
  params: {
    location: location
    logAnalyticsWorkspaceName: loggingDeployment.outputs.logAnalyticsWorkspaceName
    userAssignedManagedIdentityName: managedIdentityDeployment.outputs.managedIdentityName
    storageAccountName: storageDeployment.outputs.storageAccountName
    rotateKeyVaultSecretFunctionAppName: names.outputs.rotateKeyVaultSecretFunctionAppName
    keyVaultName: keyVaultDeployment.outputs.keyVaultName
    appInsightsName: loggingDeployment.outputs.appInsightsName
    appSerivcePlanName: names.outputs.appServicePlanName
    rotateKeyVaultSecretFunctionEndpointName: names.outputs.rotateKeyVaultSecretFunctionEndpointName
  }
}
