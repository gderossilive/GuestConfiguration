Install-Module -Name SqlServerDsc -Force
Install-Module sqlserver -Force

Configuration SQLServerSetup {
    param (
        [string]$SourcePath = "C:\SQL2022"
    )

    Import-DscResource -ModuleName SqlServerDsc
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'

    Node localhost {
        SqlSetup 'InstallDefaultInstance' {
            InstanceName = "MSSQLSERVER"
            ProtocolName = 'TcpIp'
            Enabled = $true
            SourcePath = $SourcePath
            Features = 'SQLENGINE'
            SQLSysAdminAccounts = 'gdradmin'
            InstallSharedDir = 'C:\\Program Files\\Microsoft SQL Server'
            InstallSharedWOWDir = 'C:\\Program Files (x86)\\Microsoft SQL Server'
            InstanceDir = 'C:\\Program Files\\Microsoft SQL Server'
        }
    }

    Service 'SQLServerService' {
        Name = "MSSQLSERVER"
        Ensure = "Present"
        State = "Running"
        DependsOn = "[SqlProtocol]EnableTcpIp"
    }
}

SQLServerSetup
Start-DscConfiguration -Path .\SQLServerSetup -Wait -Verbose -Force