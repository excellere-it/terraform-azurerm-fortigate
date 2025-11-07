# =============================================================================
# FORTIGATE MODULE - NETWORKING RESOURCES
# =============================================================================
# This file contains all networking-related resources for the FortiGate
# deployment including NSGs, NSG rules, network interfaces, and public IPs.
# =============================================================================

# =============================================================================
# PUBLIC IP ADDRESSES
# =============================================================================

# Management public IP for FortiGate port1 (HA MGMT interface)
# Standard SKU required for availability zone support
# Static allocation ensures IP doesn't change on VM restart
# Only created when var.create_management_public_ip = true
# Set to false for private-only deployments (VPN/ExpressRoute access)
# Optional DDoS Protection Standard (enhanced protection beyond basic)
resource "azurerm_public_ip" "mgmt_ip" {
  count               = var.create_management_public_ip ? 1 : 0
  name                = local.pip_mgmt_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  allocation_method   = "Static"

  # SECURITY: DDoS Protection (optional - Standard plan provides enhanced protection)
  # Basic protection is included with Standard SKU at no extra cost
  # Standard plan adds: adaptive tuning, cost protection, attack analytics
  ddos_protection_mode    = var.ddos_protection_plan_id != null ? "VirtualNetworkInherited" : "VirtualNetworkInherited"
  ddos_protection_plan_id = var.ddos_protection_plan_id

  tags = local.common_tags
}

# =============================================================================
# NETWORK INTERFACES
# =============================================================================
# FortiGate requires 4 network interfaces for HA deployment:
# - port1: HA Management interface (dedicated MGMT)
# - port2: WAN/Public interface (external traffic)
# - port3: LAN/Private interface (internal traffic)
# - port4: HA Sync interface (heartbeat and session sync)

# Port1 - HA Management Interface
# Used for FortiGate administrative access and monitoring
# Public IP attached only if var.create_management_public_ip = true
# For private-only deployments, access via VPN/ExpressRoute using private IP
# Accelerated networking enabled for better performance
resource "azurerm_network_interface" "port1" {
  name                           = local.nic_port1_name
  location                       = var.location
  resource_group_name            = var.resource_group_name
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.hamgmtsubnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.port1
    primary                       = true
    public_ip_address_id          = var.create_management_public_ip ? azurerm_public_ip.mgmt_ip[0].id : null
  }

  tags = local.common_tags
}

# Port2 - WAN/Public Interface
# Used for external/internet-facing traffic
# IP forwarding enabled to allow routing through FortiGate
# Public IP association managed by HA failover (ignore_changes for public_ip_address_id)
# For HA passive instances, public IP is null until failover
resource "azurerm_network_interface" "port2" {
  name                           = local.nic_port2_name
  location                       = var.location
  resource_group_name            = var.resource_group_name
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.publicsubnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.port2
    # Only associate public IP on active FortiGate; passive gets it during failover
    public_ip_address_id = var.is_passive ? null : var.public_ip_id
  }

  lifecycle {
    ignore_changes = [ip_configuration[0].public_ip_address_id]
  }

  tags = local.common_tags
}

# Port3 - LAN/Private Interface
# Used for internal/private network traffic
# IP forwarding enabled to allow routing through FortiGate
resource "azurerm_network_interface" "port3" {
  name                           = local.nic_port3_name
  location                       = var.location
  resource_group_name            = var.resource_group_name
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.privatesubnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.port3
  }

  tags = local.common_tags
}

# Port4 - HA Sync Interface
# Dedicated interface for HA heartbeat and session synchronization
# Critical for maintaining HA cluster state between active/passive nodes
resource "azurerm_network_interface" "port4" {
  name                           = local.nic_port4_name
  location                       = var.location
  resource_group_name            = var.resource_group_name
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.hasyncsubnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.port4
  }

  tags = local.common_tags
}

# Port5 - Optional Additional Interface
# Created only when port5subnet_id and port5 are configured
# Use cases: DMZ zones, additional WAN connections, dedicated monitoring
resource "azurerm_network_interface" "port5" {
  count                          = var.port5subnet_id != null && var.port5 != null ? 1 : 0
  name                           = local.nic_port5_name
  location                       = var.location
  resource_group_name            = var.resource_group_name
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.port5subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.port5
  }

  tags = local.common_tags
}

# Port6 - Optional Additional Interface
# Created only when port6subnet_id and port6 are configured
# Use cases: DMZ zones, additional WAN connections, dedicated monitoring
resource "azurerm_network_interface" "port6" {
  count                          = var.port6subnet_id != null && var.port6 != null ? 1 : 0
  name                           = local.nic_port6_name
  location                       = var.location
  resource_group_name            = var.resource_group_name
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.port6subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.port6
  }

  tags = local.common_tags
}
