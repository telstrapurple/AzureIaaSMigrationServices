# How to install this repository

This document describes how to deploy this repository into an existing Azure subscription that has an Azure migrate project installed. Basic Azure DevOps and Pipeline knowledge is required.

## Prerequisites

The following steps need to be actioned by an Azure "Global Administrator".

1. Create a resource group for the Azure migrate Artifacts.

    - Status ✅

1. Assign the Telstra Purple Operator as owner of the resource group.

    - Status ✅

1. Assign the Telstra Purple Operator with the rights:

    - Read vNets and Subnets, Microsoft.Network/*/read

    - Read VM's and Availability groups, Microsoft.Compute/*/read

    - Subnet Joiner rights for the target and test vNet subnet. Microsoft.Network/virtualNetworks/subnets/join/action

    - Owner rights over the target resource group

    - Owner rights over the Azure Migrate resource Group

    - Status ✅

1. Create a Service Principal with the rights:

    - Read vNets and Subnets, Microsoft.Network/*/read

    - Read VM's and Availability groups, Microsoft.Compute/*/read

    - Subnet Joiner rights for the target and test vNet subnet. Microsoft.Network/virtualNetworks/subnets/join/action

    - Owner rights over the target resource group

    - Owner rights over the Azure Migrate resource Group

    - Status ✅

The following steps need to be actioned by an Azure DevOps "Project Collection Administrator".

1. Create a new Project in Azure DevOps called "Cloud-Migration".

1. Assign the Telstra Purple Operator to the "Project Administrator" group for the "Cloud-Migration" project.

1. Assign the Service Principal to the "Service connections"

    - Status ✅

## Common Steps

### Clone Repository

Clone this repository into the Azure DevOps Project

    - Status ✅

## IaaS Migration

### Update Configuration files

1. Update the file [Connect-Azure.json](..\Common\Connect-Azure.json) Connect-Azure.json with the Subscription ID and Tenant ID for all required environments.

    - Status ✅

### Create the Pipelines

1. Create the Agent Pipeline from [azure-pipelines-agentless.yml](..\azure-pipelines-agentless.yml)

1. Create the Agentless Pipeline from [azure-pipelines-agent.yml](..\azure-pipelines-agent.yml)

    - Status ✅

### Create the Environments and Approvals

1. Create an Environment for each Stage of the process:

    - StartReplication
    - UpdateMachineProperties
    - StartTestMigration
    - CleanUpTestMigration
    - StartMigration
    - EnableServices
    - StopReplication

    - Status ✅

1. Create an Approval on each Environment above.

    - Status ✅
