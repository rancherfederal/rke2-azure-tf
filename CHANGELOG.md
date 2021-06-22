# Changelog

## 04/08/2021

### Branch: `patch-rgs`

* Remove the resource group definitions throughout modules and submodules and use separate resource group module to pass into new variables.
* Change `subnet_id` from `string` to `list(string)` to support `vnet` with multiple subnets.
* Add variable `location` to use location of the resource_group dependency
* Add variable `resource_group_id` 

```hcl
resource "azurerm_lb_backend_address_pool" "bepool" {
  name            = "${var.name}-lbe-be-pool"
  loadbalancer_id = azurerm_lb.this.id
  resource_group_name = var.resource_group_name
  # Deprecated in future azurerm releases, ignore linting
  //  resource_group_name = ""
}
```
In the `azurem_lb_backend_address_pool` resource, resource_group_name is required, so it was added back in.

* `upgrade_mode = "Manual"` (line 138 in `main.tf`) since `Automatic` was throwing errors about missing parameters not set.

