param appName string
param region string
param env string

output appInsightsName string = 'ai-${appName}-${region}-${env}'
output logAnalyticsWorkspaceName string = 'la-${appName}-${region}-${env}'
output appServicePlanName string = 'asp-${appName}-${region}-${env}'
output keyVaultName string = 'kv-${appName}-${region}-${env}'
output managedIdentityName string = 'mi-${appName}-${region}-${env}'
output keyVaultSecretExpiringEventGridTopicName string = 'egt-KeyVaultSecretExpiring-${appName}-${region}-${env}'
output rotateKeyVaultSecretFunctionAppName string = 'func-RotateKeyVaultSecret-${appName}-${region}-${env}'
output rotateKeyVaultSecretFunctionEndpointName string = 'rotate-secret'
output storageAccountName string = toLower('sa${appName}${region}${env}')
