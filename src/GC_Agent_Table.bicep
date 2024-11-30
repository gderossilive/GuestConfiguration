param LAW_Name string

var TableName = 'GC-Agent_CL'

resource LAW 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: LAW_Name
}

resource LAW_Table 'Microsoft.OperationalInsights/workspaces/tables@2023-09-01' = {
  parent: LAW
  name: TableName
  properties: {
    retentionInDays: 30
    plan: 'Analytics'
    schema: {
      name: TableName
      columns: [
        { 
          name: 'TimeGenerated'
          type: 'datetime'
        }
        {
          name: 'pid'
          type: 'int'
        }
        {
          name: 'tid'
          type: 'int'
        }
        {
          name: 'service'
          type: 'string'
        }
        {
          name: 'level'
          type: 'string'
        }
        {
          name: 'id'
          type: 'string'
        }
        {
          name: 'message'
          type: 'string'
        }
      ]
    }
  }
}
