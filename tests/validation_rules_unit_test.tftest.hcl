# ============================================================================
# Unit Tests for Validation Rules
# ============================================================================
# These tests validate the module's input validation rules using expect_failures
# to ensure invalid inputs are properly rejected.

variables {
  datacenter                = "TestDC"
  cluster                   = "TestCluster"
  primary_datastore_cluster = "TestDatastoreCluster"
  template                  = "ubuntu-20.04-template"
  hostname                  = "test-validation"
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
# Test 1: Valid content_library_item_type - "ovf"
# ============================================================================
run "test_valid_content_library_item_type_ovf" {
  command = plan

  variables {
    content_library_item_type = "ovf"
  }

  # Verify that "ovf" is accepted
  assert {
    condition     = var.content_library_item_type == "ovf"
    error_message = "content_library_item_type should accept 'ovf' as valid value"
  }
}

# ============================================================================
# Test 2: Valid content_library_item_type - "iso"
# ============================================================================
run "test_valid_content_library_item_type_iso" {
  command = plan

  variables {
    content_library_item_type = "iso"
  }

  # Verify that "iso" is accepted
  assert {
    condition     = var.content_library_item_type == "iso"
    error_message = "content_library_item_type should accept 'iso' as valid value"
  }
}

# ============================================================================
# Test 3: Valid content_library_item_type - "vm-template" (default)
# ============================================================================
run "test_valid_content_library_item_type_vm_template" {
  command = plan

  variables {
    content_library_item_type = "vm-template"
  }

  # Verify that "vm-template" is accepted
  assert {
    condition     = var.content_library_item_type == "vm-template"
    error_message = "content_library_item_type should accept 'vm-template' as valid value"
  }
}

# ============================================================================
# Test 4: Default content_library_item_type value
# ============================================================================
run "test_default_content_library_item_type" {
  command = plan

  # Not setting content_library_item_type - should use default

  # Verify default is "vm-template"
  assert {
    condition     = var.content_library_item_type == "vm-template"
    error_message = "content_library_item_type should default to 'vm-template'"
  }
}

# ============================================================================
# Test 5: Invalid content_library_item_type - should fail validation
# ============================================================================
run "test_invalid_content_library_item_type" {
  command = plan

  variables {
    content_library_item_type = "invalid-type"
  }

  # Expect validation to fail for invalid value
  expect_failures = [
    var.content_library_item_type
  ]
}

# ============================================================================
# Test 6: Invalid content_library_item_type - "ova" (common mistake)
# ============================================================================
run "test_invalid_content_library_item_type_ova" {
  command = plan

  variables {
    content_library_item_type = "ova"
  }

  # Expect validation to fail - "ova" is not valid (should be "ovf")
  expect_failures = [
    var.content_library_item_type
  ]
}

# ============================================================================
# Test 7: Invalid content_library_item_type - "template" (missing "vm-" prefix)
# ============================================================================
run "test_invalid_content_library_item_type_template" {
  command = plan

  variables {
    content_library_item_type = "template"
  }

  # Expect validation to fail - must be "vm-template" not just "template"
  expect_failures = [
    var.content_library_item_type
  ]
}

# ============================================================================
# Test 8: Invalid content_library_item_type - empty string
# ============================================================================
run "test_invalid_content_library_item_type_empty" {
  command = plan

  variables {
    content_library_item_type = ""
  }

  # Expect validation to fail for empty string
  expect_failures = [
    var.content_library_item_type
  ]
}

# ============================================================================
# Test 9: Case Sensitivity of content_library_item_type
# ============================================================================
run "test_content_library_item_type_case_sensitive_uppercase" {
  command = plan

  variables {
    content_library_item_type = "OVF"
  }

  # Expect validation to fail - validation is case sensitive
  expect_failures = [
    var.content_library_item_type
  ]
}

# ============================================================================
# Test 10: Case Sensitivity - Mixed Case
# ============================================================================
run "test_content_library_item_type_case_sensitive_mixed" {
  command = plan

  variables {
    content_library_item_type = "Vm-Template"
  }

  # Expect validation to fail - must be exact lowercase match
  expect_failures = [
    var.content_library_item_type
  ]
}

# ============================================================================
# Test 11: Validation Error Message
# ============================================================================
# Note: This test verifies the validation is working, the actual error message
# "Must be one of ovf, iso, or vm-template." is defined in variables.tf
run "test_validation_error_message_check" {
  command = plan

  variables {
    content_library_item_type = "wrong"
  }

  # Expect validation to fail with descriptive error
  expect_failures = [
    var.content_library_item_type
  ]
}
