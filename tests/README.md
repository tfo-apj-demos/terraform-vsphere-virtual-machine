# Terraform vSphere Virtual Machine - Test Suite

This directory contains the test suite for the vSphere Virtual Machine Terraform module. The tests are written using Terraform's native testing framework and validate the module's logic without requiring a live vSphere environment.

## Test Structure

All tests in this directory are **unit tests** that use the `command = plan` mode with **mock providers**. This approach provides:

- ✅ **Fast execution** - Tests complete in seconds
- ✅ **No infrastructure costs** - No real vSphere resources are created
- ✅ **No credentials needed** - Tests run entirely locally
- ✅ **Predictable results** - Mock providers return consistent values
- ✅ **Safe experimentation** - Test destructive operations without risk

## Test Files

### 1. `hostname_generation_unit_test.tftest.hcl`
Tests the module's conditional hostname generation logic:
- When hostname is provided → uses that hostname directly
- When hostname is empty/null → generates hostname using `random_pet` + `random_integer`
- Verifies the format: `{pet}-{number}` (e.g., "happy-dolphin-5678")

**Key Tests:**
- Hostname provided (no random resources created)
- Hostname empty string (random resources created)
- Hostname null (random resources created)
- Hostname not set/default (random resources created)
- Output consistency

### 2. `default_configuration_unit_test.tftest.hcl`
Tests default values and resource configuration:
- Default CPU count (2)
- Default memory (2048 MB)
- Default disk size (40 GB)
- Default network adapter type (vmxnet3)
- Template property inheritance (guest_id, firmware, scsi_type)
- SCSI controller count calculation
- Default customization settings

**Key Tests:**
- Default compute resources
- Custom compute resources
- Template inheritance
- Disk configuration
- Virtualization settings (EPT/RVI, HV mode)
- Time synchronization
- Resource pool selection

### 3. `network_configuration_unit_test.tftest.hcl`
Tests network configuration parsing and validation:
- DHCP detection (case insensitive: "dhcp", "DHCP", "Dhcp")
- Static IP parsing (format: "192.168.1.100/24")
- Multiple network interfaces
- Network name preservation
- IP address and netmask extraction

**Key Tests:**
- Single DHCP network
- Single static IP network
- Multiple networks (mixed DHCP and static)
- Network name preservation (spaces allowed)
- Common netmask values (/8, /16, /24, /32)
- Gateway configuration
- DNS server and suffix configuration
- Custom network adapter types

### 4. `validation_rules_unit_test.tftest.hcl`
Tests input validation rules using `expect_failures`:
- Valid values for `content_library_item_type`: "ovf", "iso", "vm-template"
- Invalid values that should fail validation
- Case sensitivity of validation rules

**Key Tests:**
- Valid values (ovf, iso, vm-template)
- Default value (vm-template)
- Invalid values (expect failures)
- Common mistakes ("ova" instead of "ovf", "template" instead of "vm-template")
- Empty string validation
- Case sensitivity

### 5. `outputs_unit_test.tftest.hcl`
Tests module output values:
- `virtual_machine_id` - VM resource ID
- `virtual_machine_name` - VM hostname
- `ip_address` - VM IP address
- `guest_id` - Guest OS identifier
- `power_state` - VM power state
- `vsphere_compute_cluster_id` - Cluster ID

**Key Tests:**
- Output presence and format
- Output value correctness
- Output with generated hostname
- Output with custom hostname
- Output data types

## Running the Tests

### Run All Tests
```bash
cd /Users/aarone/Documents/repos/terraform-vsphere-virtual-machine
terraform test
```

### Run Specific Test File
```bash
terraform test tests/hostname_generation_unit_test.tftest.hcl
```

### Run with Verbose Output
```bash
terraform test -verbose
```

### Run Specific Test by Name
```bash
terraform test -filter=test_hostname_provided
```

## Requirements

- **Terraform** version 1.7.0 or later (for mock provider support)
- **No vSphere credentials required** - Tests use mock providers
- **No real infrastructure** - All tests run in plan mode

## Test Execution Time

All tests execute quickly since they use mock providers and plan mode:
- Individual test file: ~2-5 seconds
- Full test suite: ~15-30 seconds

## Expected Output

When all tests pass, you'll see output like:
```
tests/hostname_generation_unit_test.tftest.hcl... pass
tests/default_configuration_unit_test.tftest.hcl... pass
tests/network_configuration_unit_test.tftest.hcl... pass
tests/validation_rules_unit_test.tftest.hcl... pass
tests/outputs_unit_test.tftest.hcl... pass

Success! 5 passed, 0 failed.
```

## CI/CD Integration

These tests are designed to run in CI/CD pipelines without requiring:
- vSphere environment access
- Cloud credentials
- External dependencies
- Network connectivity (beyond downloading Terraform providers)

### Example GitHub Actions Workflow
```yaml
name: Terraform Tests

on:
  pull_request:
    branches: [ main ]
  push:
    branches: [ main ]

jobs:
  terraform-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.0

      - name: Terraform Format Check
        run: terraform fmt -check -recursive

      - name: Terraform Init
        run: terraform init

      - name: Terraform Validate
        run: terraform validate

      - name: Run Terraform Tests
        run: terraform test -verbose
```

## Test Philosophy

### What These Tests Cover
- ✅ Module logic and conditionals
- ✅ Variable transformations
- ✅ Default value application
- ✅ Input validation rules
- ✅ Output value correctness
- ✅ Resource attribute configuration
- ✅ Dynamic block generation

### What These Tests Don't Cover
- ❌ Actual vSphere API behavior
- ❌ Real resource creation
- ❌ Integration with vSphere environment
- ❌ Network connectivity issues
- ❌ Performance characteristics
- ❌ Provider authentication

### When to Use Integration Tests
For testing actual vSphere integration, you would need:
- Real vSphere environment
- Valid credentials
- Integration tests using `command = apply`
- Cleanup/teardown logic

## Contributing

When adding new features to the module:
1. Write unit tests for new logic
2. Update existing tests if behavior changes
3. Ensure all tests pass before creating a pull request
4. Use descriptive test names that explain what is being tested

## Troubleshooting

### Test Failures
If tests fail, check:
1. Terraform version (1.7.0+ required for mock providers)
2. Module syntax errors (`terraform validate`)
3. Changes to variable validation rules
4. Changes to output definitions

### Mock Provider Limitations
Mock providers:
- Only work with `command = plan` mode
- May not reflect actual provider behavior exactly
- Require manual updates when provider schemas change
- Cannot test real resource interactions

## References

- [Terraform Testing Documentation](https://developer.hashicorp.com/terraform/language/tests)
- [Terraform Test Command](https://developer.hashicorp.com/terraform/cli/commands/test)
- [Mock Providers Guide](https://developer.hashicorp.com/terraform/language/tests#mock-providers)
