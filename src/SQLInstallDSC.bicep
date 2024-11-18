param sqlServerName string
param location string = resourceGroup().location
param contentUri string = 'https://gdrrepo3423.blob.core.windows.net/machine-configuration/SQLServerInstall.zip'
param contentHash string = 'DDB4772B2762682D1AA3928C90402552ACD1E6BE'


resource myVM 'Microsoft.HybridCompute/machines@2024-07-10' existing = {
  name: sqlServerName
}

resource vmExtension 'Microsoft.HybridCompute/machines/extensions@2024-07-10' = {
  parent: myVM
  name: 'AzurePolicyforWindows'
  location: location
  tags: {
    displayName: 'VM Extensions'
  }
  properties: {
    publisher: 'Microsoft.GuestConfiguration'
    type: 'ConfigurationforWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

resource myConfiguration 'Microsoft.GuestConfiguration/guestConfigurationAssignments@2020-06-25' = {
  name: sqlServerName
  scope: myVM
  location: location
  properties: {
    guestConfiguration: {
      name: sqlServerName
      contentUri: contentUri
      contentHash: contentHash
      version: '1.0'
      assignmentType: 'ApplyAndMonitor'
    }
  }
}
