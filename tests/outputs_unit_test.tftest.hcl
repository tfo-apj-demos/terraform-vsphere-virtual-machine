# ============================================================================
# Unit Tests for Module Outputs
# ============================================================================
# These tests validate that the module outputs are properly defined and
# return expected values based on the virtual machine configuration.

variables {
  datacenter                = "TestDC"
  cluster                   = "TestCluster"
  primary_datastore_cluster = "TestDatastoreCluster"
  template                  = "ubuntu-20.04-template"
  hostname                  = "test-outputs-vm"
  networks = {
    "VM Network" = "dhcp"
  }
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
      id                  = "vm-test-12345"
      name                = "test-outputs-vm"
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
# Test 1: Virtual Machine ID Output
# ============================================================================
run "test_virtual_machine_id_output" {
  command = plan

  # Verify virtual_machine_id output is not empty
  assert {
    condition     = output.virtual_machine_id != ""
    error_message = "Output virtual_machine_id should not be empty"
  }

  # Verify format matches expected vSphere VM ID pattern
  assert {
    condition     = can(regex("^vm-", output.virtual_machine_id))
    error_message = "Output virtual_machine_id should start with 'vm-'"
  }

  # Verify output matches the VM resource ID
  assert {
    condition     = output.virtual_machine_id == vsphere_virtual_machine.this.id
    error_message = "Output virtual_machine_id should match the VM resource ID"
  }
}

# ============================================================================
# Test 2: Virtual Machine Name Output
# ============================================================================
run "test_virtual_machine_name_output" {
  command = plan

  # Verify virtual_machine_name output matches hostname
  assert {
    condition     = output.virtual_machine_name == "test-outputs-vm"
    error_message = "Output virtual_machine_name should match the hostname"
  }

  # Verify output matches local.hostname
  assert {
    condition     = output.virtual_machine_name == vsphere_virtual_machine.this.name
    error_message = "Output virtual_machine_name should match VM resource name"
  }

  # Verify output is not empty
  assert {
    condition     = output.virtual_machine_name != ""
    error_message = "Output virtual_machine_name should not be empty"
  }
}

# ============================================================================
# Test 3: IP Address Output
# ============================================================================
run "test_ip_address_output" {
  command = plan

  # Verify ip_address output is not empty
  assert {
    condition     = output.ip_address != ""
    error_message = "Output ip_address should not be empty"
  }

  # Verify IP address format
  assert {
    condition     = can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$", output.ip_address))
    error_message = "Output ip_address should be in valid IPv4 format"
  }

  # Verify output matches VM's default IP address
  assert {
    condition     = output.ip_address == vsphere_virtual_machine.this.default_ip_address
    error_message = "Output ip_address should match VM's default_ip_address"
  }

  # Verify mock value is returned
  assert {
    condition     = output.ip_address == "192.168.1.100"
    error_message = "Output ip_address should match mocked value"
  }
}

# ============================================================================
# Test 4: Guest ID Output
# ============================================================================
run "test_guest_id_output" {
  command = plan

  # Verify guest_id output is not empty
  assert {
    condition     = output.guest_id != ""
    error_message = "Output guest_id should not be empty"
  }

  # Verify guest_id matches VM resource
  assert {
    condition     = output.guest_id == vsphere_virtual_machine.this.guest_id
    error_message = "Output guest_id should match VM resource guest_id"
  }

  # Verify guest_id matches expected value from template
  assert {
    condition     = output.guest_id == "ubuntu64Guest"
    error_message = "Output guest_id should match template's guest_id"
  }
}

# ============================================================================
# Test 5: Power State Output
# ============================================================================
run "test_power_state_output" {
  command = plan

  # Verify power_state output is not empty
  assert {
    condition     = output.power_state != ""
    error_message = "Output power_state should not be empty"
  }

  # Verify power_state matches VM resource
  assert {
    condition     = output.power_state == vsphere_virtual_machine.this.power_state
    error_message = "Output power_state should match VM resource power_state"
  }

  # Verify power_state is valid value
  assert {
    condition     = contains(["on", "off", "suspended"], output.power_state)
    error_message = "Output power_state should be one of: on, off, suspended"
  }
}

# ============================================================================
# Test 6: Compute Cluster ID Output
# ============================================================================
run "test_vsphere_compute_cluster_id_output" {
  command = plan

  # Verify cluster ID output is not empty
  assert {
    condition     = output.vsphere_compute_cluster_id != ""
    error_message = "Output vsphere_compute_cluster_id should not be empty"
  }

  # Verify cluster ID format
  assert {
    condition     = can(regex("^cluster-", output.vsphere_compute_cluster_id))
    error_message = "Output vsphere_compute_cluster_id should start with 'cluster-'"
  }

  # Verify cluster ID matches mocked value
  assert {
    condition     = output.vsphere_compute_cluster_id == "cluster-456"
    error_message = "Output vsphere_compute_cluster_id should match cluster data source ID"
  }
}

# ============================================================================
# Test 7: All Outputs Defined
# ============================================================================
run "test_all_outputs_defined" {
  command = plan

  # Verify all expected outputs are defined and not null
  assert {
    condition     = output.virtual_machine_id != null
    error_message = "Output virtual_machine_id should be defined"
  }

  assert {
    condition     = output.virtual_machine_name != null
    error_message = "Output virtual_machine_name should be defined"
  }

  assert {
    condition     = output.ip_address != null
    error_message = "Output ip_address should be defined"
  }

  assert {
    condition     = output.guest_id != null
    error_message = "Output guest_id should be defined"
  }

  assert {
    condition     = output.power_state != null
    error_message = "Output power_state should be defined"
  }

  assert {
    condition     = output.vsphere_compute_cluster_id != null
    error_message = "Output vsphere_compute_cluster_id should be defined"
  }
}

# ============================================================================
# Test 8: Output with Generated Hostname
# ============================================================================
run "test_output_with_generated_hostname" {
  command = plan

  variables {
    hostname = null  # Trigger hostname generation
  }

  # Verify virtual_machine_name output contains generated hostname
  assert {
    condition     = output.virtual_machine_name == "test-pet-1234"
    error_message = "Output virtual_machine_name should contain generated hostname"
  }

  # Verify generated hostname format
  assert {
    condition     = can(regex("^[a-z]+-[0-9]+$", output.virtual_machine_name))
    error_message = "Generated hostname output should follow pattern: {word}-{number}"
  }
}

# ============================================================================
# Test 9: Outputs with Custom Hostname
# ============================================================================
run "test_outputs_with_custom_hostname" {
  command = plan

  variables {
    hostname = "my-production-vm"
  }

  # Verify custom hostname is reflected in output
  assert {
    condition     = output.virtual_machine_name == "my-production-vm"
    error_message = "Output should reflect custom hostname"
  }

  # Verify VM name matches output
  assert {
    condition     = vsphere_virtual_machine.this.name == output.virtual_machine_name
    error_message = "VM name should match output when custom hostname is provided"
  }
}

# ============================================================================
# Test 10: Output Types are Correct
# ============================================================================
run "test_output_types" {
  command = plan

  # Verify virtual_machine_id is a string
  assert {
    condition     = can(tostring(output.virtual_machine_id))
    error_message = "Output virtual_machine_id should be a string"
  }

  # Verify virtual_machine_name is a string
  assert {
    condition     = can(tostring(output.virtual_machine_name))
    error_message = "Output virtual_machine_name should be a string"
  }

  # Verify ip_address is a string
  assert {
    condition     = can(tostring(output.ip_address))
    error_message = "Output ip_address should be a string"
  }

  # Verify guest_id is a string
  assert {
    condition     = can(tostring(output.guest_id))
    error_message = "Output guest_id should be a string"
  }

  # Verify power_state is a string
  assert {
    condition     = can(tostring(output.power_state))
    error_message = "Output power_state should be a string"
  }

  # Verify vsphere_compute_cluster_id is a string
  assert {
    condition     = can(tostring(output.vsphere_compute_cluster_id))
    error_message = "Output vsphere_compute_cluster_id should be a string"
  }
}
