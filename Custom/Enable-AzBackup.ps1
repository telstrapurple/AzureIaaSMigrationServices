<#
        .SYNOPSIS
        Enables backup for migrated VM's in Azure environment.

        .DESCRIPTION
        Using the applicaiton centric Recovery Services vault created in the Application Bootstrap pipeline, create the backup job for all VM's in the CSV. I.e. End to end automation of enabling backup jobs. 

        .PARAMETER CsvFilePath
        The location of the CSV file.

        .EXAMPLE
        C:\PS> Enable-AzBackup.ps1 -CsvFilePath "..\Agentless\Applications\Example.csv"

        .NOTES
        Requires:
          - Az.Accounts
          - Az.RecoveryServices

#>
[CmdletBinding()]
Param(
    [parameter(Mandatory = $false)]
    $CsvFilePath = "..\Agentless\Applications\ADS-Prod.csv"
)

Write-Host "Importing CSV file '$CsvFilePath'"
$CSV = Import-Csv $CsvFilePath

foreach ($item in $CSV) {
    $currentSubscription = (Get-AzContext).Subscription.Id
    if ([string]::IsNullOrEmpty($item.TARGET_SUBSCRIPTION_ID)) {
        $rsvPolicy = "NonProduction-Policy"
    }
    else {
        $rsvPolicy = "Production-Policy"
        if ($currentSubscription -ne $item.TARGET_SUBSCRIPTION_ID) {
            Write-Host "Changing subscription to $($item.TARGET_SUBSCRIPTION_ID)"
            # Switch subscription if on the wrong one.
            Select-AzSubscription $item.TARGET_SUBSCRIPTION_ID
        }
    }

    $vault = Get-AzRecoveryServicesVault -ResourceGroupName $item.TARGET_RESOURCE_GROUP_NAME -ErrorAction SilentlyContinue

    if (($vault | Measure-Object).Count -eq 1) {     

        $rsvPolicyObject = Get-AzRecoveryServicesBackupProtectionPolicy -Name $rsvPolicy -VaultId $vault.ID -ErrorAction SilentlyContinue

        if ($rsvPolicyObject) {
            $result = $null;
            $result = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM -Status Registered -FriendlyName $item.TARGET_MACHINE_NAME -VaultId $vault.ID -ErrorAction SilentlyContinue
            if ($result) {
                Write-Host ("VM " + $item.TARGET_MACHINE_NAME + " is already Protected with Recovery Services Vault " + $vault.Name)
            }
            else {
                try {
                    #Enable the backup policy. Output tailored to remove properties with the word error as this was causing a failure with wrapper script.
                    Enable-AzRecoveryServicesBackupProtection `
                        -ResourceGroupName $item.TARGET_RESOURCE_GROUP_NAME `
                        -Name $item.TARGET_MACHINE_NAME`
                        -Policy $rsvPolicyObject `
                        -VaultId $vault.ID `
                        -ErrorAction Stop | Select-object ActivityId, JobId, Operation, Status, WorkloadName, StartTime, EndTime, Duration
                    Write-Host "Enabled backup on Azure Virtual Machine $($item.TARGET_MACHINE_NAME)"
                }
                catch {
                    Write-Warning ("Could not determine if VM " + $item.TARGET_MACHINE_NAME + " is protected. Maybe the VM does not exist? Please check in the Azure Portal to confirm.")
                    Continue
                }
            }
        }
        else {
            Write-Host "Could not find backup policy $($rsvPolicy) on Recovery Services Vault $($vault.Name)"
        }
        
    }
    else {
        Write-Warning "ERROR:  Either no or more than one (must equal one) Recovery Services Vault was found in resource group $($item.TARGET_RESOURCE_GROUP_NAME). Please correct before trying again."
    }
}