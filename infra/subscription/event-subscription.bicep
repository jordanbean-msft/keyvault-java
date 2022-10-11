param keyVaultSecretExpiringEventGridTopicName string
param rotateKeyVaultSecretFunctionAppName string
param location string
param keyVaultName string
param logAnalyticsWorkspaceName string
param rotateKeyVaultSecretFunctionEndpointName string

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource keyVaultSecretExpiringEventGridTopic 'Microsoft.EventGrid/systemTopics@2021-06-01-preview' = {
  name: keyVaultSecretExpiringEventGridTopicName
  location: location
  properties: {
    source: keyVault.id
    topicType: 'Microsoft.KeyVault.vaults'
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource keyVaultSecretExpiringEventGridTopicDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Logging'
  scope: keyVaultSecretExpiringEventGridTopic
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'DeliveryFailures'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource eventGridConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: 'azureeventgrid'
  location: location
  properties: {
    api: {
      name: 'azureeventgrid'
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${uriComponent(location)}/managedApis/azureeventgrid'
      type: 'Microsoft.Web/locations/managedApis'
    }
    displayName: 'azureeventgrid'
  }
}

resource rotateKeyVaultSecretFunctionApp 'Microsoft.Web/sites@2021-01-15' existing = {
  name: rotateKeyVaultSecretFunctionAppName
}

resource keyVaultSecretExpiringEventSubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2021-06-01-preview' = {
  name: '${keyVaultSecretExpiringEventGridTopic.name}/keyVaultSecretExpiringForRaiseEventFunctionAppEventSubscription'
  properties: {
    destination: {
      endpointType: 'AzureFunction'
      properties: {
        resourceId: '${rotateKeyVaultSecretFunctionApp.id}/functions/${rotateKeyVaultSecretFunctionEndpointName}'
        maxEventsPerBatch: 1
        preferredBatchSizeInKilobytes: 64
      }
    }
    filter: {
      includedEventTypes: [
        'Microsoft.KeyVault.SecretNearExpiry'
      ]
    }
    eventDeliverySchema: 'EventGridSchema'
    retryPolicy: {
      maxDeliveryAttempts: 30
      eventTimeToLiveInMinutes: 1440
    }
  }
}
