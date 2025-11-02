# FortiOS Configuration (Optional)

**Status**: FortiOS provider dependency has been removed from this module to eliminate undesirable dependency chains.

## Background

The FortiOS provider was previously required by this module, which created several issues:
- **Circular Dependencies**: FortiGate VM needed to exist before FortiOS provider could connect, but provider was initialized before resources
- **Deployment Complexity**: Required complex provider configurations and timing dependencies
- **Error Prone**: Provider connection failures would break entire deployment
- **Maintenance Burden**: Required managing FortiOS provider versions and compatibility

## Current Architecture

This module now:
1. **Deploys Azure Infrastructure Only**: Creates FortiGate VMs, NICs, storage, and related Azure resources
2. **Uses Bootstrap Configuration**: Applies initial configuration via cloud-init/custom data
3. **No FortiOS Provider Required**: Module works with standard Azure provider only

## Alternative Configuration Methods

### Method 1: Bootstrap Configuration (Recommended)
Configure FortiGate using cloud-init custom data during VM deployment:

```hcl
module "fortigate" {
  source = "app.terraform.io/infoex/fortigate/azurerm"

  # Bootstrap configuration via custom data
  custom_data = filebase64("fortigate-config.conf")

  # Or use inline configuration
  bootstrap = <<-EOT
    config system global
      set hostname ${var.hostname}
      set timezone 12
    end
    config system interface
      edit "port1"
        set mode static
        set ip ${var.management_ip}/24
      next
    end
  EOT
}
```

### Method 2: Post-Deployment Script
Use Azure Custom Script Extension or remote-exec provisioner:

```hcl
resource "azurerm_virtual_machine_extension" "fortigate_config" {
  name                 = "fortigate-config"
  virtual_machine_id   = module.fortigate.vm_id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = jsonencode({
    commandToExecute = "your-fortigate-config-script.sh"
  })

  depends_on = [module.fortigate]
}
```

### Method 3: Separate FortiOS Configuration (If Required)
If you absolutely need FortiOS provider configuration, implement it as a separate Terraform configuration that runs after infrastructure deployment:

1. **Deploy Infrastructure First**:
```bash
# Deploy FortiGate infrastructure
cd terraform-azurerm-fortigate
terraform apply
```

2. **Configure FortiGate Separately**:
Create a separate Terraform configuration (`fortigate-config/`):

```hcl
# fortigate-config/versions.tf
terraform {
  required_providers {
    fortios = {
      source  = "fortinetdev/fortios"
      version = "~> 1.20"
    }
  }
}

# fortigate-config/provider.tf
provider "fortios" {
  hostname = data.terraform_remote_state.infrastructure.outputs.fortigate_management_ip
  username = var.fortigate_username
  password = var.fortigate_password
  insecure = true
}

# fortigate-config/main.tf
data "terraform_remote_state" "infrastructure" {
  backend = "remote"
  config = {
    organization = "your-org"
    workspaces = {
      name = "fortigate-infrastructure"
    }
  }
}

# Copy resources from fortigate-config.tf.optional as needed
resource "fortios_system_global" "this" {
  hostname     = var.hostname
  timezone     = "12"
  admin_sport  = 8443
  # ... other configuration
}
```

3. **Apply Configuration**:
```bash
cd fortigate-config
terraform apply
```

## Using the Optional FortiOS Configuration File

The file `fortigate-config.tf.optional` contains the complete FortiOS provider configuration that was previously part of this module. If you need to use it:

1. **Copy to Separate Directory**:
   ```bash
   cp fortigate-config.tf.optional ../fortigate-config/main.tf
   ```

2. **Add Provider Configuration**:
   ```hcl
   provider "fortios" {
     hostname = var.fortigate_hostname
     username = var.fortigate_username
     password = var.fortigate_password
     insecure = true
   }
   ```

3. **Update Resource References**:
   - Remove references to `azurerm_linux_virtual_machine.fgtvm`
   - Remove references to module resources
   - Use data sources or variables for required values

## Benefits of This Approach

1. **Clean Separation of Concerns**: Infrastructure and configuration are separate
2. **No Circular Dependencies**: FortiOS provider only used after VM exists
3. **Flexible Deployment**: Can deploy infrastructure without configuration
4. **Better Error Handling**: Configuration failures don't affect infrastructure
5. **Easier Testing**: Can test infrastructure deployment independently
6. **Terraform Cloud Compatible**: Works better with Terraform Cloud workflows

## Migration Guide

If you're currently using the FortiOS provider with this module:

1. **Disable FortiOS Configuration**:
   ```hcl
   module "fortigate" {
     source = "app.terraform.io/infoex/fortigate/azurerm"
     version = ">= 0.3.0"  # Version without FortiOS requirement

     enable_fortigate_configuration = false
     # ... other variables
   }
   ```

2. **Remove Provider Configuration**:
   Remove any `fortios` provider blocks from your root module

3. **Apply Infrastructure Changes**:
   ```bash
   terraform apply
   ```

4. **Configure FortiGate Separately** (if needed):
   Use one of the alternative methods described above

## Example Bootstrap Configuration

Here's a complete example of configuring FortiGate via bootstrap:

```hcl
module "fortigate" {
  source  = "app.terraform.io/infoex/fortigate/azurerm"
  version = ">= 0.3.0"

  # Naming
  contact     = "security@example.com"
  environment = "production"
  location    = "eastus2"
  repository  = "infrastructure"
  workload    = "firewall"

  # VM Configuration
  resource_group_name = azurerm_resource_group.main.name
  size               = "Standard_F8s_v2"

  # Network Configuration
  hamgmtsubnet_id = azurerm_subnet.mgmt.id
  port1subnet_id  = azurerm_subnet.external.id
  port2subnet_id  = azurerm_subnet.internal.id
  port3subnet_id  = azurerm_subnet.hasync.id
  port4subnet_id  = azurerm_subnet.hamgmt.id

  # Bootstrap Configuration
  bootstrap = templatefile("fortigate-config.tftpl", {
    hostname        = "fgt-${var.environment}"
    admin_password  = random_password.fortigate.result
    port1_ip        = cidrhost(azurerm_subnet.external.address_prefixes[0], 10)
    port1_mask      = split("/", azurerm_subnet.external.address_prefixes[0])[1]
    port1_gateway   = cidrhost(azurerm_subnet.external.address_prefixes[0], 1)
    port2_ip        = cidrhost(azurerm_subnet.internal.address_prefixes[0], 10)
    port2_mask      = split("/", azurerm_subnet.internal.address_prefixes[0])[1]
    timezone        = "12"
  })

  # Authentication
  adminusername = "azureuser"
  adminpassword = random_password.fortigate.result

  # Do NOT use FortiOS provider
  enable_fortigate_configuration = false
}
```

## Support

For questions or issues:
1. Check the [module documentation](README.md)
2. Review the [FortiGate Azure deployment guide](https://docs.fortinet.com/document/fortigate-public-cloud/7.2.0/azure-administration-guide)
3. Submit issues to the module repository

## Version Compatibility

- Module versions >= 0.3.0: FortiOS provider optional (this version)
- Module versions < 0.3.0: FortiOS provider required (legacy)