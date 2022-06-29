data "azurerm_resource_group" "tp4" {
    name = "devops-TP2"
}

# Use already defined Virtual Network and Subnet
data "azurerm_virtual_network" "tp4" { 
    name = "example-network" 
    # location = var.region
    resource_group_name = data.azurerm_resource_group.tp4.name 
} 

data "azurerm_subnet" "tp4" { 
    name = "internal" 
    resource_group_name = data.azurerm_resource_group.tp4.name 
    virtual_network_name = data.azurerm_virtual_network.tp4.name 
}
