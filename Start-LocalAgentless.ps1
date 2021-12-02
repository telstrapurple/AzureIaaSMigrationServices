<#
    .SYNOPSIS
        Runs a mock of the azure-pipelines-agentless pipeline locally with the test parameters

    .DESCRIPTION
        Used for local debug of pipeline scripts so that the Pipeline does not have to be repeatedly called during debugging.

    .PARAMETER Stage
        Specifies which pipeline stage to run

    .EXAMPLE
        Start-Local.ps1 -Stage UpdateMachineProperties
        Runs the scripts for the Pipeline stage "UpdateMachineProperties"
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('StartReplication', 'UpdateMachineProperties', 'StartTestMigration', 'CleanUpTestMigration', 'StartMigration', 'StopReplication')]
    [string]
    $Stage = "StartReplication",
    [string]
    $CsvFilePath = ".\Agentless\Applications\Pilot.DEV.csv"

)

switch ($Stage) {
    "StartReplication" { $InvokeCommand = "$PSScriptRoot\Agentless\Agentless VMware automation\AzMigrate_StartReplication.ps1" }
    "UpdateMachineProperties" { $InvokeCommand = "$PSScriptRoot\Agentless\Agentless VMware automation\AzMigrate_UpdateReplicationStatus.ps1,$PSScriptRoot\Agentless\AgentlessVMwareautomation\AzMigrate_UpdateMachineProperties.ps1" }
    "StartTestMigration" { $InvokeCommand = "$PSScriptRoot\Agentless\Agentless VMware automation\AzMigrate_UpdateReplicationStatus.ps1,$PSScriptRoot\Agentless\AgentlessVMwareautomation\AzMigrate_StartTestMigration.ps1" }
    "CleanUpTestMigration" { $InvokeCommand = "$PSScriptRoot\Agentless\Agentless VMware automation\AzMigrate_UpdateReplicationStatus.ps1,$PSScriptRoot\Agentless\AgentlessVMwareautomation\AzMigrate_CleanUpTestMigration.ps1" }
    "StartMigration" { $InvokeCommand = "$PSScriptRoot\Agentless\Agentless VMware automation\AzMigrate_UpdateReplicationStatus.ps1,$PSScriptRoot\Agentless\AgentlessVMwareautomation\AzMigrate_StartMigration.ps1" }
    "StopReplication" { $InvokeCommand = "$PSScriptRoot\Agentless\Agentless VMware automation\AzMigrate_UpdateReplicationStatus.ps1,$PSScriptRoot\Agentless\AgentlessVMwareautomation\AzMigrate_StopReplication.ps1" }
}

& $PSScriptRoot\Common\Connect-Azure.ps1 -Environment Prod -Verbose -InvokeCommand $InvokeCommand -InvokeArguments $CsvFilePath