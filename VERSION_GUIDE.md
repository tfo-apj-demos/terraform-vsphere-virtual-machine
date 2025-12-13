# Module Version Guide: Pets vs Cattle

This module uses **semantic versioning** to indicate different operational behaviors:

## Version Strategy

| Version | Behavior | Icon | Use Case |
|---------|----------|------|----------|
| **v1.6.0** | 🐾 **Pets** - Template changes ignored | 🔒 | Long-lived VMs (databases, stateful apps) |
| **v2.0.0** | 🐄 **Cattle** - Template changes trigger replacement | 🔄 | Immutable infrastructure (web servers, containers) |

## Current State: v1.6.0 (Pets) - READY TO PUBLISH ✅

### What's in v1.6.0

**Files modified:**
- ✅ `main.tf` - Static lifecycle.ignore_changes list (includes template properties)
- ✅ `variables.tf` - Removed unused `pin_template_version` variable
- ✅ `README.md` - Clear "PETS VERSION" documentation
- ✅ `TEMPLATE_LIFECYCLE.md` - Updated for v1.6.0

**Lifecycle behavior:**
```hcl
lifecycle {
  ignore_changes = [
    annotation,
    extra_config,
    clone,
    ept_rvi_mode,
    hv_mode,
    guest_id,      # ← Template properties always ignored
    scsi_type,     # ←
    firmware,      # ←
  ]
}
```

**When to use v1.6.0:**
- Production databases
- Stateful applications
- Legacy systems
- Active Directory servers
- Any VM that should be stable and long-lived

**How templates are handled:**
- ✅ VMs are NOT replaced when templates are updated/deleted
- ✅ Can run `terraform plan` even after template cleanup
- ✅ To update: Use `terraform apply -replace="..."` explicitly

### Publishing v1.6.0

```bash
cd /Users/aarone/Documents/repos/terraform-vsphere-virtual-machine

# Verify tests pass
terraform init
terraform test

# Commit and tag
git add .
git commit -m "feat: v1.6.0 - pets version with template lifecycle protection"
git tag -a v1.6.0 -m "Pets version - VMs protected from template changes"
git push origin main --tags
```

The Terraform Cloud/Enterprise private registry will automatically pick up the new tag.

## Creating v2.0.0 (Cattle) - NEXT STEP

### What to Change for v2.0.0

**1. Update `main.tf` lifecycle block:**

```hcl
lifecycle {
  # Cattle version: Only ignore metadata, NOT template properties
  ignore_changes = [
    annotation,
    extra_config,
    ept_rvi_mode,
    hv_mode,
    # NOTE: clone, guest_id, scsi_type, firmware are NOT ignored
    # This allows VMs to be replaced when templates change
  ]
}
```

**2. Update `README.md` header:**

```markdown
# vSphere Virtual Machine - v2.0.0 (Cattle Version)

> **⚠️ Important:** This is the **CATTLE version** of the module. VMs created with this version **will be replaced** when templates change.
>
> 🐾 **Looking for the PETS version?** Use **v1.6.0** instead for long-lived VMs.
```

**3. Update `TEMPLATE_LIFECYCLE.md` header:**

```markdown
# Template Lifecycle Management Guide - v2.0.0 (Cattle Version)

> **📌 This documentation is for v2.0.0 - the CATTLE version**
>
> VMs created with this version **will be replaced** when templates change.
>
> 🐾 **Looking for PETS behavior?** Use **v1.6.0** instead.
```

**4. Update version comparison tables:**

Change all tables from:
```
| **v1.6.0** (this) | 🐾 **Pets** | ... |
| **v2.0.0** | 🐄 **Cattle** | ... |
```

To:
```
| **v1.6.0** | 🐾 **Pets** | ... |
| **v2.0.0** (this) | 🐄 **Cattle** | ... |
```

### Step-by-Step: Creating v2.0.0

```bash
cd /Users/aarone/Documents/repos/terraform-vsphere-virtual-machine

# Create a new branch for cattle version
git checkout -b v2-cattle

# 1. Edit main.tf - Remove guest_id, scsi_type, firmware from ignore_changes
# 2. Edit README.md - Change header to "Cattle Version"
# 3. Edit TEMPLATE_LIFECYCLE.md - Update header
# 4. Update all version comparison tables

# Test
terraform init
terraform test

# Commit and tag
git add .
git commit -m "feat: v2.0.0 - cattle version allowing template-driven replacements"
git tag -a v2.0.0 -m "Cattle version - VMs replaced when templates change"

# Merge to main (or push branch and tag)
git checkout main
git merge v2-cattle
git push origin main --tags

# Or just push the tag if you want to maintain separate branches
git push origin v2-cattle v2.0.0
```

## Usage Examples

### For Pets Workspaces (use v1.6.0)

```hcl
module "database" {
  source  = "app.terraform.io/tfo-apj-demos/virtual-machine/vsphere"
  version = "1.6.0"  # ← Pets version

  hostname = "prod-db-01"
  template = data.hcp_packer_artifact.rhel9.external_identifier

  # ... rest of config
}
```

**Workspace Settings (Terraform Cloud):**
- Add: `TF_CLI_ARGS_plan = "-refresh=false"`

### For Cattle Workspaces (use v2.0.0)

```hcl
module "web_server" {
  source  = "app.terraform.io/tfo-apj-demos/virtual-machine/vsphere"
  version = "2.0.0"  # ← Cattle version

  hostname = "web-server-01"
  template = data.hcp_packer_artifact.ubuntu.external_identifier

  # ... rest of config
}
```

**Workspace Settings:**
- Auto-apply: Enabled (optional)
- Refresh: Default (enabled)

When HCP Packer builds new template → VM will be replaced automatically

## Version Compatibility

### Upgrading FROM v1.5.x or earlier

Both v1.6.0 and v2.0.0 are compatible upgrades:

```hcl
# Change from:
version = "1.5.2"

# To (for pets):
version = "1.6.0"

# OR (for cattle):
version = "2.0.0"
```

No breaking changes in variables or outputs.

### Switching Between v1.6.0 ↔ v2.0.0

**From Pets (v1.6.0) to Cattle (v2.0.0):**
```hcl
# Simply change version - existing VMs won't be affected
version = "2.0.0"  # Changed from 1.6.0
```

Future template changes will now trigger replacements.

**From Cattle (v2.0.0) to Pets (v1.6.0):**
```hcl
# Change version - protects VMs from future template changes
version = "1.6.0"  # Changed from 2.0.0
```

Future template changes will be ignored.

## Maintenance Strategy

### Branch Strategy (Recommended)

- `main` branch = Latest stable (could track v1.6.0 or v2.0.0)
- `v1-pets` branch = Pets version (v1.6.x)
- `v2-cattle` branch = Cattle version (v2.x.x)

Tag releases from appropriate branches.

### Single Branch Strategy

Keep all versions in `main`, use tags to identify versions:

```bash
# For v1.6.x patches (pets)
git checkout v1.6.0
# make changes
git commit -m "fix: ..."
git tag v1.6.1
git push origin v1.6.1

# For v2.0.x patches (cattle)
git checkout v2.0.0
# make changes
git commit -m "fix: ..."
git tag v2.0.1
git push origin v2.0.1
```

## Testing Both Versions

Create test configurations for both:

```hcl
# tests/pets-version.tftest.hcl
run "test_pets_protection" {
  variables {
    template = "test-template-1"
  }

  # Verify VM created
  assert {
    condition     = module.vm.virtual_machine_id != ""
    error_message = "VM should be created"
  }
}

run "test_pets_no_replacement_on_template_change" {
  variables {
    template = "test-template-2"  # Different template
  }

  # Verify NO replacement (VM ID unchanged)
  assert {
    condition     = module.vm.virtual_machine_id == run.test_pets_protection.virtual_machine_id
    error_message = "Pets VMs should not be replaced when template changes"
  }
}
```

```hcl
# tests/cattle-version.tftest.hcl
run "test_cattle_replacement_on_template_change" {
  variables {
    template = "test-template-1"
  }

  # Verify VM created
  assert {
    condition     = module.vm.virtual_machine_id != ""
    error_message = "VM should be created"
  }
}

run "test_cattle_gets_replaced" {
  variables {
    template = "test-template-2"  # Different template
  }

  # Verify replacement (different VM ID)
  assert {
    condition     = module.vm.virtual_machine_id != run.test_cattle_replacement_on_template_change.virtual_machine_id
    error_message = "Cattle VMs should be replaced when template changes"
  }
}
```

## Summary

✅ **v1.6.0 (Pets) - READY TO PUBLISH**
- All code changes complete
- Documentation updated
- Tests should pass
- Ready to tag and push

🔜 **v2.0.0 (Cattle) - TODO**
- Remove template properties from lifecycle.ignore_changes
- Update README/docs headers
- Test and publish

Both versions provide clear, semantic choices for users based on their operational needs!
