# Azure template

## Parameters

Parameter name | Required | Description
-------------- | -------- | -----------
environment    | No       | Prefix for the environment (2-5 characters)
VMName         | Yes      | Storage Account type by default is standrad_lrs
correlative    | Yes      | This will be a name suffix for concatenate name resources
existingvirtualNetworkName | Yes      | Existing VNet to which the VM will connect.
existingresourcegroupVirtualNetwork | Yes      | Resource Group Name for Existing VNet to which the VM will connect.
existingsubnetName | Yes      | Existing Subnet to which the VM will connect.
existingStorageAccountName | Yes      | The name of an existing storage account to which diagnostics data is transfered.
adminUsername  | Yes      | User name for the Virtual Machine.
imageSKU       | No       | Image SKU
vmSize         | No       | Size of the virtual machine
NumbOfInstances | No       | Number of Web Servers
diskType       | No       | The type of the Storage Account created
location       | No       | Location for all resources.
adminPasswordOrKey | Yes      | SSH Key or password for the Virtual Machine. SSH key is recommended.
_artifactsLocation | No       | The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.
_artifactsLocationSasToken | No       | The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.

### environment

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Prefix for the environment (2-5 characters)

- Default value: `prd01`

### VMName

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

Storage Account type by default is standrad_lrs

### correlative

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

This will be a name suffix for concatenate name resources

### existingvirtualNetworkName

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

Existing VNet to which the VM will connect.

### existingresourcegroupVirtualNetwork

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

Resource Group Name for Existing VNet to which the VM will connect.

### existingsubnetName

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

Existing Subnet to which the VM will connect.

### existingStorageAccountName

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

- Default value: `Standard_B1ls`

### NumbOfInstances

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Number of Web Servers

- Default value: `1`

- Allowed values: `1`, `2`

### diskType

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The type of the Storage Account created

- Default value: `StandardSSDLRS`

- Allowed values: `Standard_LRS`, `StandardSSDLRS`, `Premium_LRS`

### location

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Location for all resources.

- Default value: `[resourceGroup().location]`

### adminPasswordOrKey

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

SSH Key or password for the Virtual Machine. SSH key is recommended.

### _artifactsLocation

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.

- Default value: `[deployment().properties.templateLink.uri]`

### _artifactsLocationSasToken

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.

## Outputs

Name | Type | Description
---- | ---- | -----------
FQDN | string |
PrivateIPAddress | string |

## Snippets

### Parameter file

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "metadata": {
        "template": "templates/0 generic/azuredeploywindsc.json"
    },
    "parameters": {
        "environment": {
            "value": "prd01"
        },
        "VMName": {
            "value": ""
        },
        "correlative": {
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
        "existingStorageAccountName": {
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
        "NumbOfInstances": {
            "value": 1
        },
        "diskType": {
            "value": "StandardSSDLRS"
        },
        "location": {
            "value": "[resourceGroup().location]"
        },
        "adminPasswordOrKey": {
            "reference": {
                "keyVault": {
                    "id": ""
                },
                "secretName": ""
            }
        },
        "_artifactsLocation": {
            "value": "[deployment().properties.templateLink.uri]"
        },
        "_artifactsLocationSasToken": {
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
