# Azure template

## Parameters

Parameter name | Required | Description
-------------- | -------- | -----------
VMName         | Yes      | Virtual Machine Name
existingvirtualNetworkName | Yes      | Existing VNet to which the VM will connect.
existingresourcegroupVirtualNetwork | Yes      | Resource Group Name for Existing VNet to which the VM will connect.
existingsubnetName | Yes      | Existing Subnet to which the VM will connect.
existingBootDiagnostic | Yes      | The name of an existing storage account to which diagnostics data is transfered.
adminUsername  | Yes      | User name for the Virtual Machine.
imageSKU       | No       | Image SKU
vmSize         | No       | Size of the virtual machine
NumbOfInstances | No       | Number of Web Servers
diskType       | No       | The type of the Storage Account created
location       | No       | Location for all resources.
DataDiskSize   | No       | The size for the first data disk
adminPasswordOrKey | Yes      | SSH Key or password for the Virtual Machine. SSH key is recommended.

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

Size of the virtual machine

- Default value: `Standard_F2s_v2`

### NumbOfInstances

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Number of Web Servers

- Default value: `1`

- Allowed values: `1`, `2`

### diskType

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The type of the Storage Account created

- Default value: `Standard_SSDLRS`

- Allowed values: `Standard_LRS`, `StandardSSD_LRS`, `Premium_LRS`

### location

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Location for all resources.

- Default value: `[resourceGroup().location]`

### DataDiskSize

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The size for the first data disk

- Default value: `128`

### adminPasswordOrKey

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

SSH Key or password for the Virtual Machine. SSH key is recommended.

## Snippets

### Parameter file

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "metadata": {
        "template": "templates/3 singlewinvmstatic/azuredeploysinglevm-static.json"
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
