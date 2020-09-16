locals {
  bootstrap-share-name = "bootstrapshare"
  bootstrap-sa-name = "bootstrapsa"
}

# The storage account is used for the VM Series bootstrap
# Ref: https://docs.paloaltonetworks.com/vm-series/8-1/vm-series-deployment/bootstrap-the-vm-series-firewall/bootstrap-the-vm-series-firewall-in-azure.html#idd51f75b8-e579-44d6-a809-2fafcfe4b3b6
resource "azurerm_storage_account" "bootstrap-storage-account" {
  location = var.location
  name = local.bootstrap-share-name
  account_replication_type = "LRS"
  account_tier = "Standard"
  resource_group_name = azurerm_resource_group.panorama.name
}

# Create rhe share to house the directories
### INBOUND ####
resource "azurerm_storage_share" "bootstrap-storage-share" {
  name = "bootstrapshare"
  storage_account_name = azurerm_storage_account.bootstrap-storage-account.name
  quota = 50
}

resource "azurerm_storage_share_directory" "bootstrap-storage-directories" {
  for_each = toset([
    "content",
    "software",
    "license"])
  name = each.key
  share_name = azurerm_storage_share.bootstrap-storage-share.name
  storage_account_name = azurerm_storage_account.bootstrap-storage-account.name
}

resource "azurerm_storage_share_directory" "bootstrap-config-directory" {
  share_name = azurerm_storage_share.bootstrap-storage-share.name
  storage_account_name = azurerm_storage_account.bootstrap-storage-account.name
  name = "config"
}

resource "null_resource" "uploadfile" {
  provisioner "local-exec" {
    command = "az storage file upload --account-name ${azurerm_storage_account.bootstrap-storage-account.name} --account-key ${azurerm_storage_account.bootstrap-storage-account.primary_access_key} --share-name ${azurerm_storage_share.bootstrap-storage-share.name} --source .\\bootstrap_configs\\init-cfg-inbound.txt --path config/init-cfg.txt"
  }
  depends_on = [azurerm_storage_share_directory.bootstrap-config-directory]
}

#### OUTBOUND #####
resource "azurerm_storage_share" "outbound-bootstrap-storage-share" {
  name = "obbootstrapshare"
  storage_account_name = azurerm_storage_account.bootstrap-storage-account.name
  quota = 50
}

resource "azurerm_storage_share_directory" "outbound-bootstrap-storage-directories" {
  for_each = toset([
    "content",
    "software",
    "license"])
  name = each.key
  share_name = azurerm_storage_share.outbound-bootstrap-storage-share.name
  storage_account_name = azurerm_storage_account.bootstrap-storage-account.name
}

resource "azurerm_storage_share_directory" "outbound-bootstrap-config-directory" {
  share_name = azurerm_storage_share.outbound-bootstrap-storage-share.name
  storage_account_name = azurerm_storage_account.bootstrap-storage-account.name
  name = "config"
}

resource "null_resource" "outbound-uploadfile" {
  provisioner "local-exec" {
    command = "az storage file upload --account-name ${azurerm_storage_account.bootstrap-storage-account.name} --account-key ${azurerm_storage_account.bootstrap-storage-account.primary_access_key} --share-name ${azurerm_storage_share.outbound-bootstrap-storage-share.name} --source .\\bootstrap_configs\\init-cfg-outbound.txt --path config/init-cfg.txt"
  }
  depends_on = [azurerm_storage_share_directory.outbound-bootstrap-config-directory]
}