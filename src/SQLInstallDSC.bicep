param sqlServerName string
param location string = resourceGroup().location
param contentUri string = 'https://github.com/gderossilive/GuestConfiguration/raw/refs/heads/main/Files/SQLServerInstall.zip'
param contentHash string = 'ac94b0f0911522bb5bd83bb5c665acedb93b03714159cfd207e812c2556e36e4'


resource myVM 'Microsoft.HybridCompute/machines@2024-07-10' existing = {
  name: sqlServerName
}

/*
resource vmExtension 'Microsoft.HybridCompute/machines/extensions@2024-07-31-preview' = {
  parent: myVM
  name: 'AzurePolicyforWindows'
  location: location
  properties: {
    publisher: 'Microsoft.GuestConfiguration'
    type: 'GuestConfiguration'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}*/

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
