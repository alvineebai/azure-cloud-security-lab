provider "azurerm" {
  features {}
    tenant_id = "cdaaeb8b-7691-4b93-8dfa-79a1b19687b6"
}
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "secure_network_dev_rg" {
  name     = "secure-network-dev-rg"
  location = "Central US"
}

resource "azurerm_virtual_network" "secure_network_dev_vnet" {
  name                = "secure-network-dev-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "Central US"
  resource_group_name = "secure-network-dev-rg"
}

resource "azurerm_subnet" "web_subnet" {
  name                 = "web-subnet"
  resource_group_name  = "secure-network-dev-rg"
  virtual_network_name = "secure-network-dev-vnet"
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet"
  resource_group_name  = "secure-network-dev-rg"
  virtual_network_name = "secure-network-dev-vnet"
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "db_subnet" {
  name                 = "db-subnet"
  resource_group_name  = "secure-network-dev-rg"
  virtual_network_name = "secure-network-dev-vnet"
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_network_security_group" "secure_network_dev_nsg_web" {
  name                = "secure-network-dev-nsg-web"
  location            = "Central US"
  resource_group_name = "secure-network-dev-rg"
}

resource "azurerm_network_security_rule" "web_https_inbound"{
    name                       = "Allow-HTTPS-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.1.0/24"
    resource_group_name        = "secure-network-dev-rg"
    network_security_group_name = "secure-network-dev-nsg-web"
  }


resource "azurerm_network_security_group" "secure-network_dev_nsg_app" {
  name                = "secure-network-dev-nsg-app"
  location            = "Central US"
  resource_group_name = "secure-network-dev-rg"
}

resource "azurerm_network_security_rule" "app_https_inbound"{
    name                       = "Allow-HTTPS-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.2.0/24"
    resource_group_name        = "secure-network-dev-rg"
    network_security_group_name = "secure-network-dev-nsg-app"
  }

resource "azurerm_network_security_group" "secure-network_dev_nsg_db" {
  name                = "secure-network-dev-nsg-db"
  location            = "Central US"
  resource_group_name = "secure-network-dev-rg"
}

resource "azurerm_network_security_rule" "db_https_inbound"{
    name                       = "Allow-HTTPS-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1443"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "10.0.3.0/24"
    resource_group_name        = "secure-network-dev-rg"
    network_security_group_name = "secure-network-dev-nsg-db"
  }

resource "azurerm_subnet_network_security_group_association" "web_nsg_association" {
  subnet_id                 = azurerm_subnet.web_subnet.id
  network_security_group_id = azurerm_network_security_group.secure_network_dev_nsg_web.id
}

resource "azurerm_subnet_network_security_group_association" "app_nsg_association" {
  subnet_id                 = azurerm_subnet.app_subnet.id
  network_security_group_id = azurerm_network_security_group.secure-network_dev_nsg_app.id
}

resource "azurerm_subnet_network_security_group_association" "db_nsg_association" {
  subnet_id                 = azurerm_subnet.db_subnet.id
  network_security_group_id = azurerm_network_security_group.secure-network_dev_nsg_db.id
}

resource "azurerm_virtual_network" "secure_network_dev_hub_vnet" {
  name                = "secure-network-dev-hub-vnet"
  address_space       = ["10.10.0.0/16"]
  location            = "Central US"
  resource_group_name = "secure-network-dev-rg"
}

resource "azurerm_subnet" "azure_firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = "secure-network-dev-rg"
  virtual_network_name = "secure-network-dev-hub-vnet"
  address_prefixes     = ["10.10.1.0/26"]
}

resource "azurerm_subnet" "azure_bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = "secure-network-dev-rg"
  virtual_network_name = "secure-network-dev-hub-vnet"
  address_prefixes     = ["10.10.2.0/26"]
}

resource "azurerm_virtual_network_peering" "hub_to_spoke1" {
  name                      = "hub-to-spoke"
  resource_group_name       = "secure-network-dev-rg"
  virtual_network_name      = "secure-network-dev-hub-vnet"
  remote_virtual_network_id = azurerm_virtual_network.secure_network_dev_vnet.id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "spoke-to-hub"
  resource_group_name       = "secure-network-dev-rg"
  virtual_network_name      = "secure-network-dev-vnet"
  remote_virtual_network_id = azurerm_virtual_network.secure_network_dev_hub_vnet.id
    allow_virtual_network_access = true
}


resource "azurerm_public_ip" "firewall_public_ip" {
  name                = "secure-network-dev-firewall-pip"
  location            = "Central US"
  resource_group_name = "secure-network-dev-rg"
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "azure_firewall" {
  name                = "secure-network-dev-firewall"
  location            = "Central US"
  resource_group_name = "secure-network-dev-rg"
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  firewall_policy_id = azurerm_firewall_policy.azure_firewall_policy.id

  ip_configuration {
    name                 = "ecure-network-dev-firewall-ipconfig"
    subnet_id            = azurerm_subnet.azure_firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.firewall_public_ip.id
  }
}

resource "azurerm_firewall_policy" "azure_firewall_policy" {
  name                = "secure-network-dev-firewall-policy"
  resource_group_name = "secure-network-dev-rg"
  location            = "Central US"
}

resource "azurerm_firewall_policy_rule_collection_group" "network_rules" {
  name               = "secure-network-dev-firewall-rules"
  firewall_policy_id = azurerm_firewall_policy.azure_firewall_policy.id
  priority           = 100

  application_rule_collection {
    name     = "allow-ubuntu-updates"
    priority = 100
    action   = "Allow"

    rule {
      name = "allow-ubuntu-repositories"

      source_addresses = [
        "10.0.1.0/24",
        "10.0.2.0/24"
      ]

      protocols {
        type = "Http"
        port = 80
      }

      protocols {
        type = "Https"
        port = 443
      }

      destination_fqdns = [
        "*.ubuntu.com",
        "*.ubuntu.archive.com"
      ]
    }
  }
}

resource "azurerm_route_table" "web_route_table" {
  name                = "secure-network-dev-rt-web"
  location            = "central US"
  resource_group_name = "secure-network-dev-rg"
}

resource "azurerm_route" "web_to_firewall" {
  name                = "web-to-firewall"
  resource_group_name = "secure-network-dev-rg"
  route_table_name    = "secure-network-dev-rt-web"
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "VirtualAppliance"
    next_hop_in_ip_address = "10.10.1.4"
}

resource "azurerm_subnet_route_table_association" "web_route_table_association" {
  subnet_id      = azurerm_subnet.web_subnet.id
  route_table_id = azurerm_route_table.web_route_table.id
}

resource "azurerm_route_table" "app_route_table" {
  name                = "secure-network-dev-rt-app"
  location            = "central US"
  resource_group_name = "secure-network-dev-rg"
}

resource "azurerm_route" "app_to_firewall" {
  name                = "app-to-firewall"
  resource_group_name = "secure-network-dev-rg"
  route_table_name    = "secure-network-dev-rt-app"
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "VirtualAppliance"
  next_hop_in_ip_address = "10.10.1.4"

}

resource "azurerm_subnet_route_table_association" "app_route_table_association" {
  subnet_id      = azurerm_subnet.app_subnet.id
  route_table_id = azurerm_route_table.app_route_table.id
}

resource "azurerm_network_interface" "web_nic" {
  name                = "secure-network-dev-nic-web"
  location            = "Central US"
  resource_group_name = "secure-network-dev-rg"
  ip_configuration {
    name                          = "web-ipconfig"
    subnet_id                     = azurerm_subnet.web_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_linux_virtual_machine" "web_vm" {
  name                = "secure-network-dev-vm-web"
  resource_group_name = "secure-network-dev-rg"
  location            = "central US"
  size                = "Standard_D2s_v6"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.web_nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

resource "azurerm_network_interface" "app_nic" {
  name                = "secure-network-dev-nic-app"
  location            = "Central US"
  resource_group_name = "secure-network-dev-rg"
  ip_configuration {
    name                          = "app-ipconfig"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_linux_virtual_machine" "app_vm" {
  name                = "secure-network-dev-vm-app"
  resource_group_name = "secure-network-dev-rg"
  location            = "central US"
  size                = "Standard_D2s_v6"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.app_nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/myvmkey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.secure_network_dev_app_identity.id
    ]
  }
}

resource "azurerm_public_ip" "bastion_public_ip" {
  name                = "secure-network-dev-bastion-pip"
  location            = "central US"
  resource_group_name = "secure-network-dev-rg"
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "azure_bastion" {
  name                = "secure-network-dev-bastion"
  location            = "Central US"
  resource_group_name = "secure-network-dev-rg"
  ip_configuration {
    name                 = "secure-network-dev-bastion-ipconfig"
    subnet_id            = azurerm_subnet.azure_bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_public_ip.id
  }
}

resource "azurerm_subnet" "app_gateway_subnet" {
  name                 = "app-gateway-subnet"
  resource_group_name  = "secure-network-dev-rg"
  virtual_network_name = "secure-network-dev-vnet"
  address_prefixes     = ["10.0.4.0/24"]
}

resource "azurerm_public_ip" "application_gateway_public_ip" {
  name                = "secure-network-dev-application-gateway-pip"
  resource_group_name = "secure-network-dev-rg"
  location            = "centralus"
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_web_application_firewall_policy" "application_gateway_waf" {
  name                = "secure-network-dev-application-gateway-waf-policy"
  resource_group_name = "secure-network-dev-rg"
  location            = "centralus"

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb    = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

resource "azurerm_application_gateway" "application_gateway" {
  name                = "secure-network-dev-application-gateway"
  resource_group_name = "secure-network-dev-rg"
  location            = "centralus"

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  firewall_policy_id = azurerm_web_application_firewall_policy.application_gateway_waf.id

  gateway_ip_configuration {
    name      = "secure-network-dev-application-gateway-ipconfig"
    subnet_id = azurerm_subnet.app_gateway_subnet.id
  }

  frontend_ip_configuration {
    name                 = "secure-network-dev-application-gateway-frontend-ipconfig"
    public_ip_address_id = azurerm_public_ip.application_gateway_public_ip.id
  }

  frontend_port {
    name = "secure-network-dev-application-gateway-http-port"
    port = 80
  }

  backend_address_pool {
    name = "secure-network-dev-application-gateway-backend-pool"
    ip_addresses = ["10.0.1.4"]
  }

  backend_http_settings {
    name                  = "secure-network-dev-application-gateway-backend-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "secure-network-dev-application-gateway-http-listener"
    frontend_ip_configuration_name = "secure-network-dev-application-gateway-frontend-ipconfig"
    frontend_port_name             = "secure-network-dev-application-gateway-http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "secure-network-dev-application-gateway-routing-rule"
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = "secure-network-dev-application-gateway-http-listener"
    backend_address_pool_name  = "secure-network-dev-application-gateway-backend-pool"
    backend_http_settings_name = "secure-network-dev-application-gateway-backend-settings"
  }
}

resource "azurerm_mssql_server" "secure_network_dev_sql_server" {
  name                         = "secure-network-dev-sql-server"
  resource_group_name          = "secure-network-dev-rg"
  location                     = "centralus"
  version                      = "12.0"
  administrator_login          = "azureuser"
  administrator_login_password = "@Honeybear27!"
  minimum_tls_version          = "1.2"

  public_network_access_enabled = false
}

resource "azurerm_mssql_database" "secure_network_dev_sql_database" {
  name         = "secure-network-dev-db"
  server_id    = azurerm_mssql_server.secure_network_dev_sql_server.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 2
  sku_name     = "S0"
  enclave_type = "VBS"

  # prevent the possibility of accidental data loss
  lifecycle {
    prevent_destroy = false
  }
}

resource "azurerm_private_endpoint" "secure_network_dev_sql_private_endpoint" {
  name                = "secure-network-dev-sql-private-endpoint"
  location            = "centralus"
  resource_group_name = "secure-network-dev-rg"
  subnet_id           = azurerm_subnet.db_subnet.id

  private_service_connection {
    name                           = "secure-network-dev-sql-connection"
    private_connection_resource_id = azurerm_mssql_server.secure_network_dev_sql_server.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_dns_zone" "secure_network_dev_sql_private_dns" {
  name                = "privatelink.database.windows.net"
  resource_group_name = "secure-network-dev-rg"
}

resource "azurerm_private_dns_zone_virtual_network_link" "secure_network_dev_sql_dns_link" {
  name                  = "secure-network-dev-sql-dns-link"
  private_dns_zone_id   = azurerm_private_dns_zone.secure_network_dev_sql_private_dns.id
  virtual_network_id    = azurerm_virtual_network.secure_network_dev_vnet.id
}
  
resource "azurerm_user_assigned_identity" "secure_network_dev_app_identity" {
  location            = "centralus"
  name                = "secure-network-dev-app-identity"
  resource_group_name = "secure-network-dev-rg"
}

resource "azurerm_key_vault" "secure_network_dev_keyvault" {
  name                        = "secure-network-dev-kv"
  location                    = "centralus"
  resource_group_name         = "secure-network-dev-rg"
  rbac_authorization_enabled  = true
  enabled_for_disk_encryption = true
tenant_id = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 90
  purge_protection_enabled    = false

  sku_name = "standard"
}

resource "azurerm_role_assignment" "secure_network_dev_kv_secrets_user" {
  scope                = azurerm_key_vault.secure_network_dev_keyvault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.secure_network_dev_app_identity.principal_id
}

resource "azurerm_key_vault_secret" "secure_network_dev_test_secret" {
  name         = "app-test-secret"
  value        = "HelloFromKeyVault"
  key_vault_id = azurerm_key_vault.secure_network_dev_keyvault.id
}