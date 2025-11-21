# ============================================================================
# Unit Tests for Hostname Generation Logic
# ============================================================================
# These tests validate the conditional hostname generation logic:
# - When hostname is provided, use it directly
# - When hostname is not provided (empty or null), generate using random_pet + random_integer

variables {
  datacenter                = "TestDC"
  cluster                   = "TestCluster"
  primary_datastore_cluster = "TestDatastoreCluster"
  template                  = "ubuntu-20.04-template"
  networks = {
    "VM Network" = "dhcp"
  }
}

# Mock vSphere provider to avoid requiring real infrastructure
mock_provider "vsphere" {
  # Mock datacenter data source
  mock_data "vsphere_datacenter" {
    defaults = {
      id   = "datacenter-123"
      name = "TestDC"
    }
  }

  # Mock compute cluster data source
  mock_data "vsphere_compute_cluster" {
    defaults = {
      id                = "cluster-456"
      name              = "TestCluster"
      datacenter_id     = "datacenter-123"
      resource_pool_id  = "respool-789"
    }
  }

  # Mock datastore cluster data source
  mock_data "vsphere_datastore_cluster" {
    defaults = {
      id            = "datastore-cluster-111"
      name          = "TestDatastoreCluster"
      datacenter_id = "datacenter-123"
    }
  }

  # Mock network data source
  mock_data "vsphere_network" {
    defaults = {
      id            = "network-222"
      name          = "VM Network"
      datacenter_id = "datacenter-123"
      type          = "Network"
    }
  }

  # Mock virtual machine template data source
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

  # Mock virtual machine resource
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

# Mock random provider for hostname generation
mock_provider "random" {
  mock_resource "random_pet" {
    defaults = {
      id     = "happy-dolphin"
      length = 1
    }
  }

  mock_resource "random_integer" {
    defaults = {
      id     = "5678"
      result = 5678
      min    = 1000
      max    = 9999
    }
  }
}

# ============================================================================
# Test 1: Hostname provided - should use the provided hostname
# ============================================================================
run "test_hostname_provided" {
  command = plan

  variables {
    hostname = "my-custom-hostname"
  }

  # Verify that the local.hostname value matches the provided hostname
  assert {
    condition     = vsphere_virtual_machine.this.name == "my-custom-hostname"
    error_message = "VM name should match the provided hostname when hostname is set"
  }

  # Verify that random_pet resource is NOT created when hostname is provided
  assert {
    condition     = length(random_pet.this) == 0
    error_message = "random_pet should not be created when hostname is provided"
  }

  # Verify that random_integer resource is NOT created when hostname is provided
  assert {
    condition     = length(random_integer.this) == 0
    error_message = "random_integer should not be created when hostname is provided"
  }
}

# ============================================================================
# Test 2: Hostname empty string - should generate hostname
# ============================================================================
run "test_hostname_empty_string" {
  command = plan

  variables {
    hostname = ""
  }

  # Verify that random_pet resource IS created when hostname is empty
  assert {
    condition     = length(random_pet.this) == 1
    error_message = "random_pet should be created when hostname is empty string"
  }

  # Verify that random_integer resource IS created when hostname is empty
  assert {
    condition     = length(random_integer.this) == 1
    error_message = "random_integer should be created when hostname is empty string"
  }

  # Verify that the hostname follows the expected format: {pet}-{number}
  assert {
    condition     = vsphere_virtual_machine.this.name == "happy-dolphin-5678"
    error_message = "Generated hostname should follow format: {pet}-{number}"
  }

  # Verify random_pet has correct length
  assert {
    condition     = random_pet.this[0].length == 1
    error_message = "random_pet should have length of 1"
  }

  # Verify random_integer has correct range
  assert {
    condition     = random_integer.this[0].min == 1000
    error_message = "random_integer min should be 1000"
  }

  assert {
    condition     = random_integer.this[0].max == 9999
    error_message = "random_integer max should be 9999"
  }
}

# ============================================================================
# Test 3: Hostname null - should generate hostname
# ============================================================================
run "test_hostname_null" {
  command = plan

  variables {
    hostname = null
  }

  # Verify that random_pet resource IS created when hostname is null
  assert {
    condition     = length(random_pet.this) == 1
    error_message = "random_pet should be created when hostname is null"
  }

  # Verify that random_integer resource IS created when hostname is null
  assert {
    condition     = length(random_integer.this) == 1
    error_message = "random_integer should be created when hostname is null"
  }

  # Verify that the hostname follows the expected format
  assert {
    condition     = vsphere_virtual_machine.this.name == "happy-dolphin-5678"
    error_message = "Generated hostname should follow format: {pet}-{number} when hostname is null"
  }
}

# ============================================================================
# Test 4: Hostname not set (uses default) - should generate hostname
# ============================================================================
run "test_hostname_not_set" {
  command = plan

  # Do not set hostname variable at all - uses default (null)

  # Verify that random_pet resource IS created when hostname uses default
  assert {
    condition     = length(random_pet.this) == 1
    error_message = "random_pet should be created when hostname is not set (default null)"
  }

  # Verify that random_integer resource IS created when hostname uses default
  assert {
    condition     = length(random_integer.this) == 1
    error_message = "random_integer should be created when hostname is not set (default null)"
  }

  # Verify that the hostname follows the expected format
  assert {
    condition     = vsphere_virtual_machine.this.name == "happy-dolphin-5678"
    error_message = "Generated hostname should follow format: {pet}-{number} when hostname not set"
  }
}

# ============================================================================
# Test 5: Verify hostname output consistency
# ============================================================================
run "test_hostname_output" {
  command = plan

  variables {
    hostname = "test-output-vm"
  }

  # Verify that the output value matches the VM name
  assert {
    condition     = output.virtual_machine_name == "test-output-vm"
    error_message = "Output virtual_machine_name should match the VM name"
  }

  # Verify that the output matches the provided hostname
  assert {
    condition     = output.virtual_machine_name == var.hostname
    error_message = "Output virtual_machine_name should match the provided hostname variable"
  }
}
