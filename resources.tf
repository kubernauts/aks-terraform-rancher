data "azurerm_resource_group" "rg" {
  name = "${var.resource_group_name}"
}

resource "azurerm_virtual_network" "test" {
   name                = "${var.virtual_network_name}"
   location            = "${data.azurerm_resource_group.rg.location}"
   resource_group_name = "${data.azurerm_resource_group.rg.name}"
   address_space       = ["${var.virtual_network_address_prefix}"]

   subnet {
     name           = "${var.aks_subnet_name}"
     address_prefix = "${var.aks_subnet_address_prefix}" 
   }

   tags = "${var.tags}"
 }

 data "azurerm_subnet" "kubesubnet" {
   name                 = "${var.aks_subnet_name}"
   virtual_network_name = "${azurerm_virtual_network.test.name}"
   resource_group_name  = "${data.azurerm_resource_group.rg.name}"
 }

resource "azurerm_kubernetes_cluster" "k8s" {
  name       = "${var.aks_name}"
  location   = "${data.azurerm_resource_group.rg.location}"
  dns_prefix = "${var.aks_dns_prefix}"
  kubernetes_version = "${var.kubernetes_version}"

  resource_group_name = "${data.azurerm_resource_group.rg.name}"

  linux_profile {
    admin_username = "${var.vm_user_name}"

    ssh_key {
      key_data = "${file(var.public_ssh_key_path)}"
    }
  }

  addon_profile {
    http_application_routing {
      enabled = false
    }
  }

  agent_pool_profile {
    name            = "agentpool"
    count           = "${var.aks_agent_count}"
    vm_size         = "${var.aks_agent_vm_size}"
    os_type         = "Linux"
    os_disk_size_gb = "${var.aks_agent_os_disk_size}"
    vnet_subnet_id  = "${data.azurerm_subnet.kubesubnet.id}"
  }

/*
  service_principal {
    client_id     = "${var.aks-service-principal-app-id}"
    client_secret = "${var.aks-service-principal-client-secret}"
  }
*/

  service_principal {
      client_id     = "${var.client_id}"
      client_secret = "${var.client_secret}"
    }

  role_based_access_control {
      azure_active_directory {
              server_app_id     = "${var.rbac_server_app_id}"
              server_app_secret = "${var.rbac_server_app_secret}"
              client_app_id     = "${var.rbac_client_app_id}"
              tenant_id         = "${var.tenant_id}"
      }
      enabled = true
  }



  network_profile {
    network_plugin     = "azure"
    dns_service_ip     = "${var.aks_dns_service_ip}"
    docker_bridge_cidr = "${var.aks_docker_bridge_cidr}"
    service_cidr       = "${var.aks_service_cidr}"
  }

  # depends_on = ["azurerm_virtual_network.test", "azurerm_application_gateway.network"]
  depends_on = ["azurerm_virtual_network.test"]
  tags       = "${var.tags}"
}
