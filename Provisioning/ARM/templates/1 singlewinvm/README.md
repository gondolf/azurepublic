# Single Windows VM Deployment

Create a Windows Stand Alone Single VM

This template deploy a Windows vm based on a parameter file, with the following features:

1. Boot Diagnostics

2. Network Accelerate

3. Data Disk

## Parameters

Parameter name | Required | Description
-------------- | -------- | -----------
VMName         | Yes      | Virtual Machine Name
existingvirtualNetworkName | Yes      | Existing VNet to which the VM will connect.
existingresourcegroupVirtualNetwork | Yes      | Resource Group Name for Existing VNet to which the VM will connect.
existingsubnetName | Yes      | Existing Subnet to which the VM will connect.
existingBootDiagnostic | Yes      | The name of an existing storage account for boot diagnostic use.
adminUsername  | Yes      | User name for the Virtual Machine.
imageSKU       | No       | Image SKU which are tested with this ARM Template
vmSize         | No       | Size of the virtual machine
NumbOfInstances | No       | Number of  Server Instances that are required
diskType       | No       | The type of the Storage Account
location       | No       | Location for all resources. By default the vm is deployed in the same location as the resource group
networkaccelerate | No       | Enable / Disable Network Accelerate for Network Interface
DataDiskSize   | No       | The size for the first data disk
adminPasswordOrKey | Yes      | SSH Key or password for the Virtual Machine. SSH key is recommended for Linux vm's.

### VMName

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

Virtual Machine Name

### existingvirtualNetworkName

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

Existing VNet to which the VM will connect.

### existingresourcegroupVirtualNetwork

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

Resource Group Name for Existing VNet to which the VM will connect.

### existingsubnetName

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

Existing Subnet to which the VM will connect.

### existingBootDiagnostic

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

The name of an existing storage account for boot diagnostic use.

### adminUsername

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

User name for the Virtual Machine.

### imageSKU

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Image SKU which are tested with this ARM Template

- Default value: `2019-Datacenter`

- Allowed values: `2012-R2-Datacenter`, `2016-Datacenter`, `2019-Datacenter`

### vmSize

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Size of the virtual machine

- Default value: `Standard_F2s_v2`

### NumbOfInstances

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Number of  Server Instances that are required

- Default value: `1`

- Allowed values: `1`, `2`

### diskType

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The type of the Storage Account

- Default value: `Standard_SSDLRS`

- Allowed values: `Standard_LRS`, `StandardSSD_LRS`, `Premium_LRS`

### location

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Location for all resources. By default the vm is deployed in the same location as the resource group

- Default value: `[resourceGroup().location]`

### networkaccelerate

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Enable / Disable Network Accelerate for Network Interface

- Default value: `True`

### DataDiskSize

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The size for the first data disk

- Default value: `128`

### adminPasswordOrKey

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

SSH Key or password for the Virtual Machine. SSH key is recommended for Linux vm's.

## Snippets

### Parameter file

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "metadata": {
        "template": "templates/1 singlewinvm/azuredeploysinglevm.json"
    },
    "parameters": {
        "VMName": {
            "value": ""
        },
        "existingvirtualNetworkName": {
            "value": ""
        },
        "existingresourcegroupVirtualNetwork": {
            "value": ""
        },
        "existingsubnetName": {
            "value": ""
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
            "value": "Standard_F2s_v2"
        },
        "NumbOfInstances": {
            "value": 1
        },
        "diskType": {
            "value": "Standard_SSDLRS"
        },
        "location": {
            "value": "[resourceGroup().location]"
        },
        "networkaccelerate": {
            "value": true
        },
        "DataDiskSize": {
            "value": 128
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
