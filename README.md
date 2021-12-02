# Azure IaaS Migration Services

## Introduction

This repository contains artefacts that help with traditional lift-and-shift or disaster recovery of IaaS workloads (physical or virtual machines) that can be moved with Azure Site Recovery Configuration/Azure Migrate server/appliance using an automated first approach. This automated approach is made possible by:

1. Leveraging Azure DevOps pipelines, and
1. Modified scripts provided by Microsoft at https://github.com/Azure/azure-docs-powershell-samples/tree/master/azure-migrate (MIT License).

This repository makes it possible for any IT System Administrator or IT Department to be able to offer IaaS Migration-as-a-Service capability to their own organisation/ business. All the end-user needs to know is how to pre-fill the appropriate CSV file consumed by the pipelines.

In summary, the steps for the pipelines are:

- First, read the CSV file that contains the configuration data for the "application environment".

- Validate that all of the information in the CSV file is correct by checking that the subscription, resource groups and resources exist.

- Support the migration of the workload or set up the DR in Azure for the workload.

### What is an "Application Environment"?

An application environment is a logical group of IaaS workloads that should migrate together. That could for example be your entire footprint (big bang cut over) or logical groupings of servers like SAP, File Shares that you want to migrate in a particular batch.

It's highly recommended that when you set up your application environment groupings, you create the same 'logical groupings' in Azure Migrate itself for the application assessments. This will help with right sizing and not needing to specify the Sku size yourself.

## Prerequisites

### Azure Migrate

1. Create your Azure Migrate resource group and Azure Migrate Project in the Azure Portal. See [Create and manage projects](https://docs.microsoft.com/en-us/azure/migrate/create-manage-projects) and [Assign Azure roles using the Azure portal](https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal?tabs=current).
1. Make sure you have configured and installed the Agent and/or Agentless appliances in your on-premises environments. See [Azure Migrate appliance](https://docs.microsoft.com/en-us/azure/migrate/migrate-appliance)
1. Document your SubcriptionId, TenantId and Azure Migrate Resource Group and Project Names from the Azure Portal. They are needed for the CSV files later.
1. Update `Connect-Azure.json` with the tenantId and subscriptionId for each Azure Subscription where workloads will be migrated to.

### Azure DevOps

1. Create an Azure AD Service Principal that is an owner to the Azure Subscription(s) where your Azure Migrate Project is and where you wish to failover workloads to. See [Use the portal to create an Azure AD application and service principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal) and
   - It's noted that these permissions are excessive, but as Azure Migrate must be able to create resource locks, the Service Principal does require significant permissions.
1. Create an Azure Storage Account with a single container, ideally in the same Resource Group as the Azure Migrate Project, to keep logs of pipeline runs for you.
   - Grant the Service Principal blob contributor rights to the created storage account.
   - Update the `azure-jobs.yml` file with the storage account name and container created.
1. Configure the Service Principal as a Service Connection inside your Azure DevOps project. See [Manage service connections](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints).
1. Create the Agentless and Agent migratins pipelines in Azure DevOps. See [Create your first pipeline](https://docs.microsoft.com/en-us/azure/devops/pipelines/create-first-pipeline).

## Running the Migration Pipeline

**Note:** The operator will require Project Contributor rights to perform the tasks described here.

### Create CSV file

1. Copy the [Agentless](Agentless/Applications/Example.DEV.csv) or [Agent](Agent/applications/Example.DEV.csv) example CSV to the same folder and the source example.

1. Rename the copied CSV file to the format [AppName].[Environment].csv  
   E.g. AppName.Dev.csv

### Update the CSV file

1. Each line represents a server to be migrated. Copy the second line for every server that forms the application stack.

1. Update all of the columns with the required values. Blank columns are not mandatory but can be updated if required.

1. Save, commit and push the updated CSV file.

### Run the pipeline

1. Log on to [Azure DevOps](https://dev.azure.com/).
1. Open the either your `Agentless Migration` or `Agent Migration` pipeline.
1. Click "Run Pipeline"
1. Select the Branch that the CSV was committed to
   e.g. main
1. Type the name of the CSV file.
1. Click "Stages to run"
1. Select the first stage only
1. Click "Use selected stages"
1. Click "Run"

### Repeat pipeline run for all stages

1. Once the previous step completes successfully, repeat that step for all stages one at a time.

## Migration Stages

The following details the stages in the Azure Pipelines for both Agent and Agentless migrations.

1. **StartReplication** - Starts the replication process to replicate disks to Azure.
1. **UpdateMachineProperties** - Updates the virtual machines properties.
1. **StartTestMigration** - Start the test failover step.
1. **CleanUpTestMigration** - Clean up the test failover step.
1. **StartMigration** - Cut over the workload to Azure.
1. **EnableServices** - Run custom scripts to enable services like Azure Backup.
1. **StopReplication** - Stop replicating the disks from on-premises. Aka, migration complete.
