locals {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_network_security_group" "this" {
  name = var.name

  resource_group_name = data.azurerm_resource_group.rg.name
  location = data.azurerm_resource_group.rg.location

  tags = merge({}, var.tags)
}

resource "azurerm_linux_virtual_machine_scale_set" "this" {
  name = format("vm-%s", lower(replace(var.name, "/[[:^alnum:]]/", "")))

  instances = var.instances
  resource_group_name = data.azurerm_resource_group.rg.name
  location = data.azurerm_resource_group.rg.location

  sku = var.vm_size
  custom_data = var.custom_data
  priority = var.priority
  eviction_policy = var.eviction_policy

  health_probe_id = var.health_probe_id
  upgrade_mode = "Automatic"

  admin_username = var.admin_username
  admin_ssh_key {
    username = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  dynamic "source_image_reference" {
    for_each = var.source_image_id != null ? [] : [1]
    content {
      offer = lookup(var.source_image_reference, "offer")
      publisher = lookup(var.source_image_reference, "publisher")
      sku = lookup(var.source_image_reference, "sku")
      version = lookup(var.source_image_reference, "version")
    }
  }

  network_interface {
    name = "nic-${format("vm-%s", lower(replace(var.name, "/[[:^alnum:]]/", "")))}"
    primary = true
    network_security_group_id = azurerm_network_security_group.this.id

    ip_configuration {
      name = "ipconfig-${format("vm-%s", lower(replace(var.name, "/[[:^alnum:]]/", "")))}"
      primary = true
      subnet_id = var.subnet_id

      load_balancer_backend_address_pool_ids = var.load_balancer_backend_address_pool_ids
      load_balancer_inbound_nat_rules_ids = var.load_balancer_inbound_nat_rules_ids

      dynamic "public_ip_address" {
        for_each = var.assign_public_ips ? [{}] : []
        content {
          name = "pip-${format("vm-%s", lower(replace(var.name, "/[[:^alnum:]]/", "")))}"
        }
      }
    }
  }

  identity {
    type = "UserAssigned"
    identity_ids = var.identity_ids
  }

  os_disk {
    caching = "ReadWrite"
    storage_account_type = var.os_disk_storage_account_type
  }

  automatic_instance_repair {
    enabled = var.enable_automatic_instance_repair
    grace_period = var.automatic_instance_repair_grace_period
  }

  tags = merge({}, var.tags)
}
