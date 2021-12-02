<#
    .SYNOPSIS
        Connect to an Azure tenant

    .PARAMETER Environment
        The Azure environment and subscription that is used to deploy artefacts to.

    .PARAMETER ApiId
        Used with ApiSecret for an non interactive logon to Azure.
        This is useful for pipeline logon to Azure when a Service Principal is not available.
        If no ApiId is present and a Service Principal is not available then the operator will be prompted for an interactive logon.

    .PARAMETER InvokeCommands
        Used with InvokeArguments to all another PowerShell script at the completion of this script but without ending the process.

    .PARAMETER Pipeline
        Used when this script is called by a pipline and therefore interactive logon and switching of subscriptions is not possible.

    .EXAMPLE
        .\Connect-Azure.ps1 -Environment Prod
        Connect to the Azure Prod Environment, Prompt for interactive login if not already logged in and exit.

    .EXAMPLE
        .\Connect-Azure.ps1 -InvokeCommand "$(Build.SourcesDirectory)/AzMigrate_StartReplication.ps1" -InvokeArguments "$(Build.SourcesDirectory)/Example.CSV"
        Connect to the Azure Dev Environment, Prompt for interactive login if not already logged in and then run the PowerShell script:
            AzMigrate_StartReplication.ps1
            with arguments
            Example.CSV

    .EXAMPLE
        .\Connect-Azure.ps1 -ApiId $(ApiID) -ApiSecret $(ApiSecret)
        Connect to the Azure Dev Environment with an API ID and Secret that is stored in a pipeline group and then exit. There will be no interactive logon.

    .EXAMPLE
        .\Connect-Azure.ps1 -Pipeline
        Connect to the Azure Dev Environment with the existing Pipleine credentials. There will be no interactive logon or switching of the subcription ID.
#>
[CmdletBinding()]
Param(
    [String]
    $Environment = "Dev",
    [String]
    $ApiId,
    [String]
    $ApiSecret,
    [String[]]
    $InvokeCommands,
    [String]
    $InvokeArguments,
    [switch]
    $Pipeline
)

$SaveVerbosePreference = $global:VerbosePreference

# Install and import dependencies
$Modules = @("Az.Accounts", "Az.Migrate", "Az.Resources", "Az.Storage", "Az.Network", "Az.RecoveryServices")
foreach ($Module in $Modules) {
    if (-not (Get-Module -ListAvailable -Name $Module -Verbose:$false)) {
        Write-Output "Installing module $Module"
        $global:VerbosePreference = 'SilentlyContinue'
        Install-Module -Name $Module -ErrorAction Stop -Verbose:$false -Scope CurrentUser -Force -AllowClobber | Out-Null
        $global:VerbosePreference = $SaveVerbosePreference
    }
    else {
        Write-Verbose "Module $Module already installed."
    }
}

foreach ($Module in $Modules) {
    if (-not (Get-Module -Name $Module -Verbose:$false)) {
        Write-Output "Importing $Module module"
        $global:VerbosePreference = 'SilentlyContinue'
        Import-Module -Name $Module -ErrorAction Stop -Verbose:$false | Out-Null
        $global:VerbosePreference = $SaveVerbosePreference
    }
    else {
        Write-Verbose "module $Module already imported."
    }
}
Write-Output "Finished Importing modules"

# Read the Azure subscription settings from the json.
if (Test-Path "$PsScriptRoot\Connect-Azure.json") {
    $JsonParameters = Get-Content "$PsScriptRoot\Connect-Azure.json" -Raw -ErrorAction Stop | ConvertFrom-Json
}
else {
    Write-Error "File $PsScriptRoot\Connect-Azure.json not found"
    Exit
}
$TenantId = $JsonParameters.$Environment.TenantId
$SubscriptionId = $JsonParameters.$Environment.SubscriptionId

Write-Verbose "Azure Tenant Id: $TenantId"
Write-Verbose "Azure Subscription Id: $SubscriptionId"

if ($null -eq (Get-AzContext)) {
    # Log into Azure if no connection exists.
    Write-Output "Logging into Azure"
    if ($ApiSecret.length -eq 0) {
        if ($Pipeline) {
            Write-Error "No API secrets and no existing Azure connection with Pipeline switch. Cannot logon"
            Exit 1
        }
        else {
            Write-Output "Waiting for interactive logon to complete in a Web Browser."
            Connect-AzAccount -TenantId $TenantId -SubscriptionId $SubscriptionId -ErrorAction Stop
        }
    }
    else {
        Write-Output "Connect with API ID: $ApiId"
        $ApiSecureSecret = ConvertTo-SecureString $ApiSecret -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential($ApiId , $ApiSecureSecret)
        Connect-AzAccount -TenantId $TenantId -SubscriptionId $SubscriptionId -ErrorAction Stop -Credential $Credential
    }
}
else {
    # Test if existing connection is correct or log off and back on.
    $ConnectedSubscription = (Get-AzContext).Subscription.Id
    If ($ConnectedSubscription -eq $SubscriptionId) {
        Write-Verbose "Already connected to Azure. Skipping login."
    }
    else {
        Write-Output "Requested Subscription ID: $SubscriptionId not equal to currently connected Subscription ID: $ConnectedSubscription"
        if ($Pipeline) {
            Write-Output "Pipeline Switch set. Continuing with current Subscription ID: $ConnectedSubscription"
        }
        else {
            Write-Output "Logging Out"
            Remove-AzAccount | Out-Null
            Write-Output "Logging back into Azure"
            if ($ApiSecret.length -eq 0) {
                Write-Output "Waiting for interactive logon to complete in a Web Browser."
                Connect-AzAccount -TenantId $TenantId -SubscriptionId $SubscriptionId -ErrorAction Stop
            }
            else {
                $ApiSecureSecret = ConvertTo-SecureString $ApiSecret -AsPlainText -Force
                $Credential = New-Object System.Management.Automation.PSCredential($ApiId , $ApiSecureSecret)
                Connect-AzAccount -TenantId $TenantId -SubscriptionId $SubscriptionId -ErrorAction Stop -Credential $Credential
            }
        }
    }
}
Write-Output "Finished Logging on to Azure"
# Call the next PowerShell script(s) with arguments.
if ($null -ne $InvokeCommands) {
    # Split string into array incase it has been passed incorrectly via the pipeline
    If ($InvokeCommands -match ",") {
        Write-Output "Splitting String to array"
        $InvokeCommands = $InvokeCommands.Split(",")
    }
    foreach ($InvokeCommand in $InvokeCommands) {
        # Remove leading and trailing spaces if any
        $InvokeCommand = $InvokeCommand.trim()
        Write-Output "==========================================="
        Write-Output "Starting $InvokeCommand"
        Write-Output "With Arguments: $InvokeArguments"
        Get-Item InvokeCommand.log -ErrorAction SilentlyContinue | Remove-Item
        # Start next script with the call operator "&"
        & $InvokeCommand $InvokeArguments *> InvokeCommand.log

        # Display log out put that was redirected to the log file
        Get-Content InvokeCommand.log

        # Trap any errors in the log here and terminate the pipleine
        If (Select-String -Path InvokeCommand.log -Pattern 'ERROR') {
            # Highlight failing line on screen
            Write-Output "==========================================="
            Select-String -Path InvokeCommand.log -Pattern 'ERROR'
            Write-Output "==========================================="
            # Create terminating error to "fail" the pipeline.
            Write-Error "$InvokeCommand Failed" -ErrorAction Stop
            Exit 1
        }
        Get-Item InvokeCommand.log -ErrorAction SilentlyContinue | Remove-Item
    }
}
