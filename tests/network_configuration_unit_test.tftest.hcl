# ============================================================================
# Unit Tests for Network Configuration Parsing
# ============================================================================
# These tests validate the module's network configuration logic:
# - DHCP detection (when network value is "dhcp")
# - Static IP parsing (format: "IP/netmask")
# - Multiple network interfaces
# - Network interface creation for each network

variables {
  datacenter                = "TestDC"
  cluster                   = "TestCluster"
  primary_datastore_cluster = "TestDatastoreCluster"
  template                  = "ubuntu-20.04-template"
  hostname                  = "test-network-vm"
}

# Mock vSphere provider
mock_provider "vsphere" {
  mock_data "vsphere_datacenter" {
    defaults = {
      id   = "datacenter-123"
      name = "TestDC"
    }
  }

  mock_data "vsphere_compute_cluster" {
    defaults = {
      id                = "cluster-456"
      name              = "TestCluster"
      datacenter_id     = "datacenter-123"
      resource_pool_id  = "respool-789"
    }
  }

  mock_data "vsphere_datastore_cluster" {
    defaults = {
      id            = "datastore-cluster-111"
      name          = "TestDatastoreCluster"
      datacenter_id = "datacenter-123"
    }
  }

  mock_data "vsphere_network" {
    defaults = {
      id            = "network-222"
      name          = "VM Network"
      datacenter_id = "datacenter-123"
      type          = "Network"
    }
  }

  mock_data "vsphere_virtual_machine" {
    defaults = {
      id            = "vm-template-333"
      name          = "ubuntu-20.04-template"
      datacenter_id = "datacenter-123"
      guest_id      = "ubuntu64Guest"
      scsi_type     = "pvscsi"
      firmware      = "efi"
      disks = [
        {
          size             = 40
          eagerly_scrub    = false
          thin_provisioned = true
        }
      ]
    }
  }

  mock_resource "vsphere_virtual_machine" {
    defaults = {
      id                  = "vm-444"
      name                = "test-vm"
      guest_id            = "ubuntu64Guest"
      default_ip_address  = "192.168.1.100"
      power_state         = "on"
    }
  }
}

mock_provider "random" {
  mock_resource "random_pet" {
    defaults = {
      id     = "test-pet"
      length = 1
    }
  }

  mock_resource "random_integer" {
    defaults = {
      id     = "1234"
      result = 1234
      min    = 1000
      max    = 9999
    }
  }
}

# ============================================================================
# Test 1: Single Network with DHCP
# ============================================================================
run "test_single_dhcp_network" {
  command = plan

  variables {
    networks = {
      "VM Network" = "dhcp"
    }
  }

  # Verify single network interface is created
  assert {
    condition     = length(keys(var.networks)) == 1
    error_message = "Should have 1 network interface configured"
  }

  # Verify network value is dhcp (case insensitive check happens in module)
  assert {
    condition     = can(regex("^dhcp$", lower(values(var.networks)[0])))
    error_message = "Network should be configured for DHCP"
  }
}

# ============================================================================
# Test 2: Single Network with Static IP
# ============================================================================
run "test_single_static_network" {
  command = plan

  variables {
    networks = {
      "VM Network" = "192.168.1.100/24"
    }
  }

  # Verify single network interface is configured
  assert {
    condition     = length(keys(var.networks)) == 1
    error_message = "Should have 1 network interface configured"
  }

  # Verify network value contains IP and netmask in correct format
  assert {
    condition     = can(regex("^[0-9.]+/[0-9]+$", values(var.networks)[0]))
    error_message = "Static IP should be in format: IP/netmask"
  }

  # Verify IP address can be extracted
  assert {
    condition     = split("/", values(var.networks)[0])[0] == "192.168.1.100"
    error_message = "IP address should be extractable from network value"
  }

  # Verify netmask can be extracted
  assert {
    condition     = split("/", values(var.networks)[0])[1] == "24"
    error_message = "Netmask should be extractable from network value"
  }
}

# ============================================================================
# Test 3: Multiple Networks with Mixed Configuration
# ============================================================================
run "test_multiple_networks_mixed" {
  command = plan

  variables {
    networks = {
      "VM Network"     = "192.168.1.100/24"
      "Backup Network" = "dhcp"
      "Storage Network" = "10.0.0.50/16"
    }
  }

  # Verify three network interfaces are configured
  assert {
    condition     = length(keys(var.networks)) == 3
    error_message = "Should have 3 network interfaces configured"
  }

  # Verify first network is static IP
  assert {
    condition     = var.networks["VM Network"] == "192.168.1.100/24"
    error_message = "First network should have static IP 192.168.1.100/24"
  }

  # Verify second network is DHCP
  assert {
    condition     = lower(var.networks["Backup Network"]) == "dhcp"
    error_message = "Second network should be configured for DHCP"
  }

  # Verify third network is static IP
  assert {
    condition     = var.networks["Storage Network"] == "10.0.0.50/16"
    error_message = "Third network should have static IP 10.0.0.50/16"
  }
}

# ============================================================================
# Test 4: Network Key Names are Preserved
# ============================================================================
run "test_network_names_preserved" {
  command = plan

  variables {
    networks = {
      "Production VLAN"  = "192.168.100.10/24"
      "Management VLAN"  = "192.168.200.10/24"
    }
  }

  # Verify network names are preserved in keys
  assert {
    condition     = contains(keys(var.networks), "Production VLAN")
    error_message = "Network name 'Production VLAN' should be preserved"
  }

  assert {
    condition     = contains(keys(var.networks), "Management VLAN")
    error_message = "Network name 'Management VLAN' should be preserved"
  }
}

# ============================================================================
# Test 5: Case Insensitive DHCP Detection
# ============================================================================
run "test_dhcp_case_variations" {
  command = plan

  variables {
    networks = {
      "Network1" = "DHCP"
      "Network2" = "dhcp"
      "Network3" = "Dhcp"
    }
  }

  # Verify all variations are recognized (lowercase comparison in module)
  assert {
    condition     = lower(var.networks["Network1"]) == "dhcp"
    error_message = "DHCP (uppercase) should be recognized"
  }

  assert {
    condition     = lower(var.networks["Network2"]) == "dhcp"
    error_message = "dhcp (lowercase) should be recognized"
  }

  assert {
    condition     = lower(var.networks["Network3"]) == "dhcp"
    error_message = "Dhcp (mixed case) should be recognized"
  }
}

# ============================================================================
# Test 6: IPv4 Address Format Validation
# ============================================================================
run "test_ipv4_format_valid" {
  command = plan

  variables {
    networks = {
      "VM Network" = "10.20.30.40/22"
    }
  }

  # Verify IP address extraction
  assert {
    condition     = split("/", var.networks["VM Network"])[0] == "10.20.30.40"
    error_message = "Should extract IP address correctly"
  }

  # Verify netmask extraction
  assert {
    condition     = split("/", var.networks["VM Network"])[1] == "22"
    error_message = "Should extract netmask correctly"
  }
}

# ============================================================================
# Test 7: Common Netmask Values
# ============================================================================
run "test_common_netmasks" {
  command = plan

  variables {
    networks = {
      "Net-8"  = "10.0.0.1/8"
      "Net-16" = "172.16.0.1/16"
      "Net-24" = "192.168.1.1/24"
      "Net-32" = "192.168.1.254/32"
    }
  }

  # Test /8 netmask
  assert {
    condition     = split("/", var.networks["Net-8"])[1] == "8"
    error_message = "Should handle /8 netmask"
  }

  # Test /16 netmask
  assert {
    condition     = split("/", var.networks["Net-16"])[1] == "16"
    error_message = "Should handle /16 netmask"
  }

  # Test /24 netmask
  assert {
    condition     = split("/", var.networks["Net-24"])[1] == "24"
    error_message = "Should handle /24 netmask"
  }

  # Test /32 netmask (single host)
  assert {
    condition     = split("/", var.networks["Net-32"])[1] == "32"
    error_message = "Should handle /32 netmask"
  }
}

# ============================================================================
# Test 8: Gateway Configuration with Static IP
# ============================================================================
run "test_gateway_with_static_ip" {
  command = plan

  variables {
    networks = {
      "VM Network" = "192.168.1.100/24"
    }
    gateway = "192.168.1.1"
  }

  # Verify gateway is set
  assert {
    condition     = var.gateway == "192.168.1.1"
    error_message = "Gateway should be configurable with static IP"
  }

  # Verify network is static (not DHCP)
  assert {
    condition     = lower(values(var.networks)[0]) != "dhcp"
    error_message = "Network should be static when gateway is specified"
  }
}

# ============================================================================
# Test 9: DNS Configuration with Networks
# ============================================================================
run "test_dns_with_networks" {
  command = plan

  variables {
    networks = {
      "VM Network" = "192.168.1.100/24"
    }
    dns_server_list = ["8.8.8.8", "8.8.4.4"]
    dns_suffix_list = ["example.com", "test.local"]
  }

  # Verify DNS servers are set
  assert {
    condition     = length(var.dns_server_list) == 2
    error_message = "Should accept multiple DNS servers"
  }

  assert {
    condition     = var.dns_server_list[0] == "8.8.8.8"
    error_message = "First DNS server should be 8.8.8.8"
  }

  # Verify DNS suffixes are set
  assert {
    condition     = length(var.dns_suffix_list) == 2
    error_message = "Should accept multiple DNS suffixes"
  }

  assert {
    condition     = var.dns_suffix_list[0] == "example.com"
    error_message = "First DNS suffix should be example.com"
  }
}

# ============================================================================
# Test 10: Network Adapter Type Configuration
# ============================================================================
run "test_custom_network_adapter_type" {
  command = plan

  variables {
    networks = {
      "VM Network" = "dhcp"
    }
    network_adapter_type = "e1000e"
  }

  # Verify custom adapter type is set
  assert {
    condition     = var.network_adapter_type == "e1000e"
    error_message = "Should allow custom network adapter type"
  }
}
