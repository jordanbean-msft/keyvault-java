param logAnalyticsWorkspaceName string
param appInsightsName string
param rotateKeyVaultSecretFunctionAppName string
param location string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsWorkspaceName
  location: location
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
    WorkspaceResourceId: logAnalytics.id
  }
  tags: {
    'hidden-link:${resourceGroup().id}/providers/Microsoft.Web/sites/${rotateKeyVaultSecretFunctionAppName}': 'Resource'
  }
}

output logAnalyticsWorkspaceName string = logAnalytics.name
output appInsightsName string = appInsights.name
