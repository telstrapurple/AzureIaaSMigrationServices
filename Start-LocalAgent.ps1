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
    $CsvFilePath = ".\Agentless\Applications\Pilot.csv"
)

switch ($Stage) {
    "StartReplication" { $InvokeCommand = "$PSScriptRoot\Agent\asr_startmigration.ps1" }
    "UpdateMachineProperties" { $InvokeCommand = "$PSScriptRoot\Agent\asr_replicationstatus.ps1,$PSScriptRoot\Agent\asr_updateproperties.ps1" }
    "StartTestMigration" { $InvokeCommand = "$PSScriptRoot\Agent\asr_replicationstatus.ps1,$PSScriptRoot\Agent\asr_testmigration.ps1" }
    "CleanUpTestMigration" { $InvokeCommand = "$PSScriptRoot\Agent\asr_replicationstatus.ps1,$PSScriptRoot\Agent\asr_cleanuptestmigration.ps1" }
    "StartMigration" { $InvokeCommand = "$PSScriptRoot\Agent\asr_replicationstatus.ps1,$PSScriptRoot\Agent\asr_startmigration.ps1" }
    "StopReplication" { $InvokeCommand = "$PSScriptRoot\Agent\asr_replicationstatus.ps1,$PSScriptRoot\Agent\asr_postmigration.ps1" }
}

& $PSScriptRoot\Common\Connect-Azure.ps1 -Environment Prod -Verbose -InvokeCommand $InvokeCommand -InvokeArguments $CsvFilePath