/*
provider "azurerm" {
    version = "~>1.22"
}
*/

terraform {
  backend "azurerm" {
    storage_account_name  = "acemesa"
    container_name        = "tfstate"
    key                   = "aceme-management.tfstate"
  }
}