# data "azurerm_virtual_network" "tp4" { 
#     name = "example-network" 
#     # address_space = ["10.3.0.0/16"] 
#     # location = var.region
#     resource_group_name = data.azurerm_resource_group.tp4.name 
# } 

# data "azurerm_subnet" "tp4" { 
#     name = "internal" 
#     resource_group_name = data.azurerm_resource_group.tp4.name 
#     virtual_network_name = azurerm_virtual_network.tp4.name 
#     # address_prefixes = ["10.0.1.0/24"] 
# }

# 5. Define a New Public IP Address
resource "azurerm_public_ip" "tp4ip" { 
    name = "myIp1" 
    location = var.region
    resource_group_name = data.azurerm_resource_group.tp4.name
    allocation_method = "Dynamic" 
    sku = "Basic" 
} 

# 6. Define a Network Interface for our VM
resource "azurerm_network_interface" "tp4nic" { 
    name = "tp4-nic" 
    location = var.region
    resource_group_name = data.azurerm_resource_group.tp4.name

    ip_configuration { 
        name = data.azurerm_subnet.tp4.name
        subnet_id = data.azurerm_subnet.tp4.id
        private_ip_address_allocation = "Dynamic" 
        public_ip_address_id = azurerm_public_ip.tp4ip.id 
    } 
} 

# 7. Define the Virtual Machine
resource "azurerm_linux_virtual_machine" "myterraformvm" { 
    name = "devops-20210311"   
    location = var.region
    resource_group_name = data.azurerm_resource_group.tp4.name
    network_interface_ids = [azurerm_network_interface.tp4nic.id]
    size = "Standard_D2s_v3" 
    # computer_name = "devops-20210311"
    admin_username = "devops" 
    # admin_password = "Password123!" 

    # admin_ssh_key {
    #     username   = "devops"
    #     public_key = file("~/.ssh/id_rsa.pub")
    # }

    admin_ssh_key {
        username = "devops"
        public_key = tls_private_key.ssh.public_key_openssh
    }

    source_image_reference { 
        publisher = "Canonical" 
        offer = "UbuntuServer" 
        sku = "16.04-LTS" 
        version = "latest" 
    } 

    os_disk { 
        name = "myFDisk"
        caching = "ReadWrite" 
        storage_account_type = "Standard_LRS" 
    } 
} 

# tls_private_key - RSA key of size 4096 bits
resource "tls_private_key" "ssh" {
    algorithm = "RSA"
    rsa_bits  = 4096
}

# private_key_pem
output "private_key" {
  value = tls_private_key.ssh.private_key_pem
  sensitive = true
}