# =============================================================================
# FORTIGATE MODULE - MONITORING & DIAGNOSTICS
# =============================================================================
# This file contains monitoring and diagnostic resources for the FortiGate
# deployment including Azure Monitor diagnostic settings and NSG flow logs.
# =============================================================================

# =============================================================================
# VM DIAGNOSTIC SETTINGS
# =============================================================================

# Diagnostic settings for FortiGate VM
# Collects metrics and sends to Log Analytics workspace
# Only created when enable_diagnostics = true
resource "azurerm_monitor_diagnostic_setting" "vm" {
  count                      = var.enable_diagnostics && var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${local.computer_name}-vm-diagnostics"
  target_resource_id         = local.vm_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # VM Metrics
  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = var.diagnostic_retention_days > 0
      days    = var.diagnostic_retention_days
    }
  }
}

# =============================================================================
# NETWORK INTERFACE DIAGNOSTIC SETTINGS
# =============================================================================

# Diagnostic settings for port1 (Management) NIC
resource "azurerm_monitor_diagnostic_setting" "port1" {
  count                      = var.enable_diagnostics && var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${local.computer_name}-port1-diagnostics"
  target_resource_id         = azurerm_network_interface.port1.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = var.diagnostic_retention_days > 0
      days    = var.diagnostic_retention_days
    }
  }
}

# Diagnostic settings for port2 (WAN/Public) NIC
resource "azurerm_monitor_diagnostic_setting" "port2" {
  count                      = var.enable_diagnostics && var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${local.computer_name}-port2-diagnostics"
  target_resource_id         = azurerm_network_interface.port2.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = var.diagnostic_retention_days > 0
      days    = var.diagnostic_retention_days
    }
  }
}

# Diagnostic settings for port3 (LAN/Private) NIC
resource "azurerm_monitor_diagnostic_setting" "port3" {
  count                      = var.enable_diagnostics && var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${local.computer_name}-port3-diagnostics"
  target_resource_id         = azurerm_network_interface.port3.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = var.diagnostic_retention_days > 0
      days    = var.diagnostic_retention_days
    }
  }
}

# Diagnostic settings for port4 (HA Sync) NIC
resource "azurerm_monitor_diagnostic_setting" "port4" {
  count                      = var.enable_diagnostics && var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${local.computer_name}-port4-diagnostics"
  target_resource_id         = azurerm_network_interface.port4.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = var.diagnostic_retention_days > 0
      days    = var.diagnostic_retention_days
    }
  }
}
