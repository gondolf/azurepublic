# Update Cluster Windows VM Deployment

Add Windows VM to an existing Availability Set Deployment

This template will create one or more new Windows vm to an existing Availability set, based on a parameter file, with the following features:

1. Dedicate storage for Boot Diagnostics

2. Network Accelerate

3. Static IP Address for Network Interface

4. Data Disk

5. Availability Set

6. Custom Script Extension

## Parameters

| Parameter name                                  | Required | Description                                                                                                |
| ----------------------------------------------- | -------- | ---------------------------------------------------------------------------------------------------------- |
| VMName                                          | Yes      | Virtual Machine Name, for more than 1 vm use brackets and quotation marks                                  |
| existingCustomScriptStorageAccountName          | Yes      | Name of the storage account.                                                                               |
| existingvirtualNetworkName                      | Yes      | An existing virtual network  where the vm's will be allocated.                                             |
| existingsubnetName                              | Yes      | Name of an existing subnet to allocate vm ip address.                                                      |
| existingresourcegroupVirtualNetwork             | Yes      | Resource group name, which contains an existing virtual network  where the vm's will be deployed           |
| existingCustomScriptResourcegroupStorageAccount | Yes      | Resource Group Name, which contains the Storage account used for CustomScript.                             |
| networkaccelerate                               | No       | Enable / Disable Network Accelerate for Network Interface.                                                 |
| existingBootDiagnostic                          | Yes      | The name of an existing storage account to which diagnostics data is transfered.                           |
| adminUsername                                   | Yes      | User name for the Virtual Machine.                                                                         |
| imageSKU                                        | No       | Image SKU                                                                                                  |
| vmSize                                          | No       | List of current vm sizes, to add a new vm size modify this template                                        |
| DataDiskSize                                    | No       | Size for Data Disk                                                                                         |
| nicDeleteOption                                 | No       | Switch between detach or delete to specify nic behavior when the vm be deleted                             |
| OSdiskType                                      | No       | Disk Type for Operating System Disk                                                                        |
| DatadiskType                                    | No       | Disk Type for Data Disk                                                                                    |
| location                                        | No       | Location for all resources. If no location is specified, the resource group deployment location  will used |
| AvailabilitySetName                             | No       | Select an existing availability                                                                            |
| adminPasswordOrKey                              | Yes      | Password credential  for the Virtual Machine administrator.                                                |

### VMName

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

Virtual Machine Name, for more than 1 vm use brackets and quotation marks 

### existingCustomScriptStorageAccountName

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

Name of the storage account.

### existingvirtualNetworkName

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

An existing virtual network  where the vm's will be allocated.

- Allowed values: `avnetyeceu1aut01`, `avnetyeceu1dec01`, `avnetyeceu1uat01`, `avnetyeceu1prd01`, `avnetyeceu1hub01`

### existingsubnetName

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

Name of an existing subnet to allocate vm ip address.

- Allowed values: `web`, `app`, `data`, `asnetwebprd01`, `asnetdcsbol01`

### existingresourcegroupVirtualNetwork

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

Resource group name, which contains an existing virtual network  where the vm's will be deployed

### existingCustomScriptResourcegroupStorageAccount

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

Resource Group Name, which contains the Storage account used for CustomScript.

### networkaccelerate

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Enable / Disable Network Accelerate for Network Interface.

- Default value: `True`

### existingBootDiagnostic

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

The name of an existing storage account to which diagnostics data is transfered.

### adminUsername

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

User name for the Virtual Machine.

### imageSKU

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Image SKU

- Default value: `2019-Datacenter`

- Allowed values: `2012-R2-Datacenter`, `2016-Datacenter`, `2019-Datacenter`

### vmSize

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

List of current vm sizes, to add a new vm size modify this template 

- Default value: `Standard_B1ls`

- Allowed values: `Standard_D2as_v5`, `Standard_B1s`, `Standard_DS2_v2`, `Standard_D8s_v4`, `Standard_D4as_v4`, `Standard_D16as_v4`, `Standard_F2s_v2`, `Standard_F8s_v2`, `Standard_F16s_v2`, `Standard_F32s_v2`

### DataDiskSize

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Size for Data Disk

- Default value: `32`

- Allowed values: `32`, `64`, `128`, `256`, `512`, `1024`

### nicDeleteOption

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Switch between detach or delete to specify nic behavior when the vm be deleted

- Default value: `Delete`

### OSdiskType

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Disk Type for Operating System Disk

- Default value: `StandardSSD_LRS`

- Allowed values: `Standard_LRS`, `StandardSSD_LRS`, `Premium_LRS`

### DatadiskType

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Disk Type for Data Disk

- Default value: `StandardSSD_LRS`

- Allowed values: `Standard_LRS`, `StandardSSD_LRS`, `Premium_LRS`

### location

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Location for all resources. If no location is specified, the resource group deployment location  will used 

- Default value: `[resourceGroup().location]`

### AvailabilitySetName

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Select an existing availability

- Default value: `MyAvailabilitySet`

### adminPasswordOrKey

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

Password credential  for the Virtual Machine administrator.

## Snippets

### Parameter file

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "metadata": {
        "template": "MANAGE/AZURE/ARM/CLUSTER-WIN-BaseLine-AS/azuredeploy.json"
    },
    "parameters": {
        "VMName": {
            "value": []
        },
        "existingCustomScriptStorageAccountName": {
            "value": ""
        },
        "existingvirtualNetworkName": {
            "value": ""
        },
        "existingsubnetName": {
            "value": ""
        },
        "existingresourcegroupVirtualNetwork": {
            "value": ""
        },
        "existingCustomScriptResourcegroupStorageAccount": {
            "value": ""
        },
        "networkaccelerate": {
            "value": true
        },
        "existingBootDiagnostic": {
            "value": ""
        },
        "adminUsername": {
            "value": ""
        },
        "imageSKU": {
            "value": "2019-Datacenter"
        },
        "vmSize": {
            "value": "Standard_B1ls"
        },
        "DataDiskSize": {
            "value": 32
        },
        "nicDeleteOption": {
            "value": "Delete"
        },
        "OSdiskType": {
            "value": "StandardSSD_LRS"
        },
        "DatadiskType": {
            "value": "StandardSSD_LRS"
        },
        "location": {
            "value": "[resourceGroup().location]"
        },
        "AvailabilitySetName": {
            "value": "MyAvailabilitySet"
        },
        "adminPasswordOrKey": {
            "reference": {
                "keyVault": {
                    "id": ""
                },
                "secretName": ""
            }
        }
    }
}
```
