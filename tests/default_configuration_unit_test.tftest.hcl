# ============================================================================
# Unit Tests for Default Configuration
# ============================================================================
# These tests validate that the module applies correct default values and
# creates resources with expected configurations when using minimal inputs.

variables {
  datacenter                = "TestDC"
  cluster                   = "TestCluster"
  primary_datastore_cluster = "TestDatastoreCluster"
  template                  = "ubuntu-20.04-template"
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
# Test 1: Default CPU and Memory Configuration
# ============================================================================
run "test_default_compute_resources" {
  command = plan

  variables {
    hostname = "test-defaults"
  }

  # Verify default CPU count is 2
  assert {
    condition     = vsphere_virtual_machine.this.num_cpus == 2
    error_message = "Default num_cpus should be 2"
  }

  # Verify default memory is 2048 MB (2 GB)
  assert {
    condition     = vsphere_virtual_machine.this.memory == 2048
    error_message = "Default memory should be 2048 MB"
  }
}

# ============================================================================
# Test 2: Custom CPU and Memory Configuration
# ============================================================================
run "test_custom_compute_resources" {
  command = plan

  variables {
    hostname  = "test-custom-compute"
    num_cpus  = 4
    memory    = 8192
  }

  # Verify custom CPU count
  assert {
    condition     = vsphere_virtual_machine.this.num_cpus == 4
    error_message = "num_cpus should be 4 when explicitly set"
  }

  # Verify custom memory
  assert {
    condition     = vsphere_virtual_machine.this.memory == 8192
    error_message = "memory should be 8192 MB when explicitly set"
  }
}

# ============================================================================
# Test 3: Default Network Adapter Type
# ============================================================================
run "test_default_network_adapter" {
  command = plan

  variables {
    hostname = "test-network"
  }

  # Verify default network adapter type is vmxnet3
  assert {
    condition     = var.network_adapter_type == "vmxnet3"
    error_message = "Default network_adapter_type should be vmxnet3"
  }
}

# ============================================================================
# Test 4: Guest ID and Firmware from Template
# ============================================================================
run "test_template_inheritance" {
  command = plan

  variables {
    hostname = "test-template-props"
  }

  # Verify guest_id is inherited from template
  assert {
    condition     = vsphere_virtual_machine.this.guest_id == "ubuntu64Guest"
    error_message = "guest_id should be inherited from template"
  }

  # Verify firmware is inherited from template
  assert {
    condition     = vsphere_virtual_machine.this.firmware == "efi"
    error_message = "firmware should be inherited from template"
  }

  # Verify scsi_type is inherited from template
  assert {
    condition     = vsphere_virtual_machine.this.scsi_type == "pvscsi"
    error_message = "scsi_type should be inherited from template"
  }
}

# ============================================================================
# Test 5: Default Disk Size
# ============================================================================
run "test_default_disk_size" {
  command = plan

  variables {
    hostname = "test-disk"
  }

  # Verify default disk_0_size is 40 GB
  assert {
    condition     = var.disk_0_size == 40
    error_message = "Default disk_0_size should be 40 GB"
  }
}

# ============================================================================
# Test 6: Custom Disk Size
# ============================================================================
run "test_custom_disk_size" {
  command = plan

  variables {
    hostname    = "test-custom-disk"
    disk_0_size = 100
  }

  # Verify custom disk size is applied
  assert {
    condition     = var.disk_0_size == 100
    error_message = "disk_0_size should be 100 GB when explicitly set"
  }
}

# ============================================================================
# Test 7: Sync Time with Host
# ============================================================================
run "test_time_sync" {
  command = plan

  variables {
    hostname = "test-timesync"
  }

  # Verify sync_time_with_host is enabled
  assert {
    condition     = vsphere_virtual_machine.this.sync_time_with_host == true
    error_message = "sync_time_with_host should be enabled by default"
  }
}

# ============================================================================
# Test 8: EPT/RVI and HV Mode Defaults
# ============================================================================
run "test_virtualization_defaults" {
  command = plan

  variables {
    hostname = "test-virt-defaults"
  }

  # Verify ept_rvi_mode is automatic
  assert {
    condition     = vsphere_virtual_machine.this.ept_rvi_mode == "automatic"
    error_message = "ept_rvi_mode should be 'automatic' by default"
  }

  # Verify hv_mode is hvAuto
  assert {
    condition     = vsphere_virtual_machine.this.hv_mode == "hvAuto"
    error_message = "hv_mode should be 'hvAuto' by default"
  }
}

# ============================================================================
# Test 9: Default Wait Timeout
# ============================================================================
run "test_guest_net_timeout" {
  command = plan

  variables {
    hostname = "test-timeout"
  }

  # Verify wait_for_guest_net_timeout is 120 seconds
  assert {
    condition     = vsphere_virtual_machine.this.wait_for_guest_net_timeout == 120
    error_message = "wait_for_guest_net_timeout should be 120 seconds by default"
  }
}

# ============================================================================
# Test 10: SCSI Controller Count with No Extra Disks
# ============================================================================
run "test_scsi_controller_count_default" {
  command = plan

  variables {
    hostname = "test-scsi-default"
  }

  # Verify SCSI controller count is 1 when no extra disks
  assert {
    condition     = vsphere_virtual_machine.this.scsi_controller_count == 1
    error_message = "scsi_controller_count should be 1 (length(extra_disks) + 1) when no extra disks"
  }
}

# ============================================================================
# Test 11: SCSI Controller Count with Extra Disks
# ============================================================================
run "test_scsi_controller_count_with_disks" {
  command = plan

  variables {
    hostname = "test-scsi-extra"
    extra_disks = [
      {
        path         = "[datastore1] vm/disk1.vmdk"
        disk_sharing = "sharingNone"
        datastore_id = "datastore-111"
      },
      {
        path         = "[datastore1] vm/disk2.vmdk"
        disk_sharing = "sharingNone"
        datastore_id = "datastore-111"
      }
    ]
  }

  # Verify SCSI controller count increases with extra disks
  assert {
    condition     = vsphere_virtual_machine.this.scsi_controller_count == 3
    error_message = "scsi_controller_count should be 3 (2 extra disks + 1) when 2 extra disks are configured"
  }
}

# ============================================================================
# Test 12: Default Customization Enabled
# ============================================================================
run "test_default_customization" {
  command = plan

  variables {
    hostname = "test-customization"
  }

  # Verify enable_customization is true by default
  assert {
    condition     = var.enable_customization == true
    error_message = "enable_customization should be true by default"
  }
}

# ============================================================================
# Test 13: Resource Pool from Cluster
# ============================================================================
run "test_resource_pool_from_cluster" {
  command = plan

  variables {
    hostname = "test-resource-pool"
  }

  # Verify resource_pool_id comes from cluster when resource_pool var is empty
  assert {
    condition     = vsphere_virtual_machine.this.resource_pool_id == "respool-789"
    error_message = "resource_pool_id should use cluster's resource_pool_id when resource_pool variable is not set"
  }
}

# ============================================================================
# Test 14: Default Empty Tags
# ============================================================================
run "test_default_tags" {
  command = plan

  variables {
    hostname = "test-default-tags"
  }

  # Verify tags default to empty map
  assert {
    condition     = var.tags == {}
    error_message = "tags should default to empty map"
  }

  # Verify VM tags are null when no tags provided
  assert {
    condition     = vsphere_virtual_machine.this.tags == null
    error_message = "VM tags should be null when no tags are configured"
  }
}
