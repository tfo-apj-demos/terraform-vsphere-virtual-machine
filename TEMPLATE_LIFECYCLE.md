# Template Lifecycle Management Guide - v2.0.0 (Cattle Version)

> **📌 This documentation is for v2.0.0 - the CATTLE version**
>
> VMs created with this version **will be replaced** when templates change.
>
> 🐾 **Looking for PETS behavior?** Use **v1.6.0** instead.

This document explains how to handle vSphere template lifecycle issues when using HCP Packer with automated template cleanup.

## Problem Overview

When using HCP Packer to manage VM templates with automated cleanup (via webhooks), old templates are regularly deleted from vSphere. This causes Terraform data source errors:

```
Error: error fetching virtual machine: vm 'base-rhel-9-20251203085132' not found
```

## Solution: Version-Based Behavior (v2.0.0 - Cattle)

This version (v2.0.0) implements **automatic replacement** when templates change - ideal for immutable infrastructure patterns.

### Cattle Mode (v2.0.0 - This Version)
- **Use case**: Immutable infrastructure, ephemeral VMs, auto-scaling workloads
- **Behavior**: VMs are **automatically replaced** when templates are updated
- **Template updates**: Automatic when using HCP Packer `latest` channel
- **Best for**: Web servers, API servers, containerized workloads, CI/CD environments

### Pets Mode (v1.6.0 - Alternative Version)
- **Use case**: Stateful VMs, databases, legacy applications
- **Behavior**: VMs are **protected** from template-related replacements
- **Template updates**: Protected - VMs never replaced due to template changes
- **Best for**: Production databases, Active Directory servers, specialized appliances

> **Note:** Choose version based on your operational model. Use v2.0.0 for cattle, v1.6.0 for pets.

## Configuration

### Terraform Cloud Workspaces

#### For Cattle Workspaces
```hcl
module "web_servers" {
  source = "app.terraform.io/your-org/virtual-machine/vsphere"

  template             = data.hcp_packer_artifact.latest.external_identifier
  pin_template_version = false  # Default - allows automatic updates

  hostname   = "web-server-01"
  num_cpus   = 2
  memory     = 4096
  datacenter = "Datacenter"
  # ... other configuration
}
```

**Workspace Settings (Terraform Cloud):**
- Auto-apply: Enabled (optional, for full automation)
- Terraform Version: Latest stable
- Refresh Mode: Default (enabled)

#### For Pet Workspaces
```hcl
module "database_servers" {
  source = "app.terraform.io/your-org/virtual-machine/vsphere"

  template             = data.hcp_packer_artifact.latest.external_identifier
  pin_template_version = true  # Prevents replacement on template changes

  hostname   = "prod-db-01"
  num_cpus   = 8
  memory     = 32768
  datacenter = "Datacenter"
  # ... other configuration
}
```

**Workspace Settings (Terraform Cloud):**
- Auto-apply: Disabled (require manual review)
- Terraform Version: Latest stable
- **Refresh Mode: Set to `-refresh=false` in workspace settings** (see below)

### Using with terraform-vsphere-single-virtual-machine Wrapper Module

```hcl
module "pet_vm" {
  source = "app.terraform.io/your-org/single-virtual-machine/vsphere"

  hostname             = "prod-app-01"
  pin_template_version = true

  os_type           = "linux"
  linux_distribution = "rhel"
  size              = "large"
  environment       = "prod"
  site              = "sydney"
  storage_profile   = "performance"
  tier              = "gold"
  security_profile  = "app-server"
  backup_policy     = "daily"
}
```

## Handling Template Deletion Scenarios

### Scenario 1: Template Deleted, Pet VM Already Exists (RECOMMENDED APPROACH)

**For Terraform Cloud workspaces:**

1. **Set workspace to skip refresh:**
   - Go to Workspace Settings → General
   - Under "Remote state management" section
   - Enable "Skip refresh" or add `-refresh=false` to Terraform CLI arguments

2. **Alternative: Temporarily disable template lookup:**
   ```hcl
   # In workspace variables or .tfvars
   # Temporarily point to ANY valid template for state operations
   template = "base-rhel-9-20251212120000"  # Any existing template
   ```

3. **Run plan/apply:**
   ```bash
   terraform plan   # Should succeed without attempting to refresh missing template
   terraform apply  # No changes should be detected for pinned resources
   ```

**For CLI usage:**
```bash
# Skip data source refresh
terraform plan -refresh=false
terraform apply -refresh=false
```

### Scenario 2: Need to Update Pet VM to New Template

When you explicitly want to update a pet VM to a new template version:

```hcl
# Step 1: Update template reference
module "pet_vm" {
  source   = "..."
  template = data.hcp_packer_artifact.latest.external_identifier  # Points to new template

  # Step 2: Temporarily disable pinning to allow the update
  pin_template_version = false
}
```

```bash
# Step 3: Apply changes (will trigger replacement)
terraform apply

# Step 4: Re-enable pinning
# Set pin_template_version = true
terraform apply
```

### Scenario 3: Cattle VM - Explicit Template Updates

For cattle VMs, explicitly trigger replacement when updating to a new template:

```hcl
module "cattle_vm" {
  source   = "..."
  template = data.hcp_packer_artifact.latest.external_identifier

  pin_template_version = false  # Semantic flag (behavior is same as true)
}
```

When HCP Packer builds a new template:
1. Update your HCP Packer channel or iteration reference (if needed)
2. Run `terraform apply -replace="module.cattle_vm.vsphere_virtual_machine.this"`
3. VM will be replaced with new template ✅

**Alternative: Use Terraform Cloud workflows**
```bash
# In Terraform Cloud, create a "rolling update" workflow
for vm in $(terraform state list | grep cattle); do
  terraform apply -replace="$vm"
  sleep 300  # Wait for health checks
done
```

## Technical Implementation Details

### What Gets Protected (Always)

The following properties are **always** in `lifecycle.ignore_changes` for all VMs:

- `annotation` - Creation timestamp
- `extra_config` - Cloud-init metadata
- `clone` - Template reference block
- `ept_rvi_mode` - CPU virtualization mode
- `hv_mode` - Hypervisor mode
- `guest_id` - Guest OS identifier
- `scsi_type` - SCSI controller type
- `firmware` - BIOS/EFI firmware type

**Why:** Terraform's `lifecycle.ignore_changes` requires a static list - dynamic expressions like `concat()` or ternary operators are not allowed. This is a Terraform limitation, not a module limitation.

These properties are derived from the template at creation time. Once set, changes to these values (from updated templates) won't trigger VM replacement.

### Data Source Error Handling

The module uses `try()` functions to gracefully handle missing template data:

```hcl
guest_id  = try(data.vsphere_virtual_machine.this[var.template].guest_id, null)
scsi_type = try(data.vsphere_virtual_machine.this[var.template].scsi_type, null)
firmware  = try(data.vsphere_virtual_machine.this[var.template].firmware, null)
```

However, the **data source itself will still fail during `terraform plan` if the template doesn't exist**. This is expected Terraform behavior and cannot be completely avoided.

### Why Refresh Control is Important

When `terraform plan` runs with refresh enabled (default):
1. Terraform attempts to refresh all data sources
2. If `data.vsphere_virtual_machine` can't find the template → **plan fails**
3. Setting `-refresh=false` skips this refresh step
4. Terraform uses cached state values instead

## Best Practices

### 1. Template Retention Strategy Alignment

Coordinate your template cleanup policy with VM operational mode:

| VM Type | `pin_template_version` | Template Retention | Recommendation |
|---------|----------------------|-------------------|----------------|
| Cattle  | `false` | Latest only | ✅ Perfect match |
| Pets    | `true` | Keep N versions (3-5) | ✅ Safe buffer |
| Pets    | `true` | Latest only | ⚠️ Requires `-refresh=false` |

### 2. Terraform Cloud Workspace Organization

**Recommended workspace structure:**

```
├── cattle-workspaces/
│   ├── web-servers-dev       (pin=false, auto-apply=true)
│   ├── web-servers-prod      (pin=false, auto-apply=false)
│   └── api-servers-dev       (pin=false, auto-apply=true)
│
└── pet-workspaces/
    ├── database-prod         (pin=true, refresh=false)
    ├── active-directory      (pin=true, refresh=false)
    └── legacy-app-prod       (pin=true, refresh=false)
```

### 3. Monitoring and Alerts

Set up notifications for:
- ✅ HCP Packer build completions
- ✅ Template cleanup webhook triggers
- ✅ Failed Terraform runs due to missing templates
- ✅ Drift detection for pet VMs

### 4. Emergency Recovery

If a pet workspace fails due to missing template:

**Option A: Point to Valid Template**
```bash
# Set TFE_PARALLELISM=1 to avoid race conditions
export TF_VAR_template="base-rhel-9-latest-known-good"
terraform plan -refresh=false
terraform apply -refresh=false
```

**Option B: Remove and Re-import Data Source**
```bash
terraform state rm 'module.vm.data.vsphere_virtual_machine.this["old-template"]'
# Update template variable to valid template
terraform plan  # Will recreate data source reference
```

## Migration Guide

### Migrating Existing Workspaces

#### For Cattle Workspaces
No action needed! The default value (`pin_template_version = false`) maintains current behavior.

#### For Pet Workspaces

1. **Add variable to module call:**
   ```hcl
   pin_template_version = true
   ```

2. **Update workspace settings in Terraform Cloud:**
   - Navigate to workspace → Settings → General
   - Add CLI argument: `-refresh=false`
   - Or set workspace variable: `TF_CLI_ARGS_plan="-refresh=false"`

3. **Test the configuration:**
   ```bash
   terraform plan  # Should show no changes
   ```

4. **Document in workspace description:**
   > "Pet workspace - uses `pin_template_version=true` and `-refresh=false`"

## Troubleshooting

### Error: "vm 'template-name' not found"

**Cause:** Template was deleted, and Terraform is trying to refresh the data source.

**Solution:**
```bash
# Temporary: Skip refresh
terraform plan -refresh=false

# Permanent: Update workspace settings (Terraform Cloud)
# or update template variable to a valid template
```

### Drift Detection Shows Template Changes

**Cause:** Template in vSphere differs from state, but pinning prevents replacement.

**Expected behavior:** This is normal for pet VMs. The VM continues running with its original template-derived properties.

### Want to Force Update a Pet VM

**Solution:**
```hcl
# Temporarily disable pinning
pin_template_version = false
```
```bash
terraform apply  # Will replace VM
```
```hcl
# Re-enable pinning after update
pin_template_version = true
```

## Additional Resources

- [HCP Packer Documentation](https://developer.hashicorp.com/packer/docs/hcp)
- [Terraform Lifecycle Meta-Arguments](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle)
- [vSphere Provider: Virtual Machine](https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs/resources/virtual_machine)

## Related Repositories

- **Template Cleanup Automation:** `/Users/aarone/Documents/repos/powershell-packer-revocation`
- **Webhook Infrastructure:** `/Users/aarone/Documents/repos/terraform-aws-packer-webhook-mutation`
