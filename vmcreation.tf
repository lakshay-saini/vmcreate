resource "azurerm_resource_group" "rg1" {
  name                     = "${var.prefix}-rg1"
  location                 = "${var.location}"
}

resource "azurerm_network_security_group" "nsg1" {
  name                = "${var.prefix}-nsg"
  location            = "${azurerm_resource_group.rg1.location}"
  resource_group_name = "${azurerm_resource_group.rg1.name}"
}

resource "azurerm_network_security_rule" "i1000" {
  name                        = "rdp-from-home"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "${var.home-ip}"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.rg1.name}"
  network_security_group_name = "${azurerm_network_security_group.nsg1.name}"
}

resource "azurerm_virtual_network" "vn1" {
  name                = "${var.prefix}-vn"
  location            = "${azurerm_resource_group.rg1.location}"
  resource_group_name = "${azurerm_resource_group.rg1.name}"
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "sn1" {
  name                      = "${var.prefix}-sn"
  resource_group_name       = "${azurerm_resource_group.rg1.name}"
  virtual_network_name      = "${azurerm_virtual_network.vn1.name}"
  address_prefix            = "10.10.10.0/24"
}

resource "azurerm_public_ip" "pip1" {
  name                    = "${var.prefix}-pip1"
  location                = "${azurerm_resource_group.rg1.location}"
  resource_group_name     = "${azurerm_resource_group.rg1.name}"
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
}

resource "azurerm_network_interface" "nic1" {
  name                      = "${var.prefix}-sql1-nic1"
  location                  = "${azurerm_resource_group.rg1.location}"
  resource_group_name       = "${azurerm_resource_group.rg1.name}"
  

  ip_configuration {
    name                          = "${var.prefix}-sql1-ip1"
    subnet_id                     = "${azurerm_subnet.sn1.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.pip1.id}"
  }
}

resource "azurerm_virtual_machine" "vm1" {
  name                          = "${var.prefix}-sql1"
  location                      = "${azurerm_resource_group.rg1.location}"
  resource_group_name           = "${azurerm_resource_group.rg1.name}"
  network_interface_ids         = ["${azurerm_network_interface.nic1.id}"]
  vm_size                       = "Standard_B4ms"
  delete_os_disk_on_termination = true

  storage_image_reference  {
    publisher="MicrosoftWindowsServer"
    offer="WindowsServer"
    sku="2016-Datacenter"
    version="latest"
  }
  
  storage_os_disk {
    name              = "${var.prefix}-sql1-disk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.prefix}-sql1"
    admin_username = "${var.adminusername}"
    admin_password = "${var.adminpassword}"
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }
}

resource "azurerm_virtual_machine_extension" "sqlserver" {
  name                 = "SqlIaasExtension"
  location             = "${azurerm_resource_group.rg1.location}"
  resource_group_name  = "${azurerm_resource_group.rg1.name}"
  virtual_machine_name = "${var.prefix}-sql1"
  publisher            = "Microsoft.SqlServer.Management"
  type                 = "SqlIaaSAgent"
  type_handler_version = "1.2"

  settings = <<SETTINGS
   null
SETTINGS
  
}