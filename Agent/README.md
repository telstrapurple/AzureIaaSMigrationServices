# Agent based migration

The scripts in this folder are cloned from [Azure Docs - How to migrate at scale](https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/migrate/how-to-migrate-at-scale.md).

## Additional value to CSV file

To support multiple Azure Subscriptions in your organisation, these scripts have been slightly modified from source. As result, one extra field exists in the CSV file that can be modified to migrate workloads into another subscription where the Azure Migrate Project does not exist.

### CSV file schema

| **Column Header**      | **Description**                                                                                                                        |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| TARGET_SUBSCRIPTION_ID | Provide the subscription ID of where the workload will be migrated to. If blank, the default AZMIGRATEPROJECT_SUBSCRIPTION_ID is used. |
