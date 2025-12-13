# vSphere Virtual Machine - v1.6.0 (Pets Version)

> **⚠️ Important:** This is the **PETS version** of the module. VMs created with this version are **protected from replacement** when templates change or are deleted.
>
> 🐄 **Looking for the CATTLE version?** Use **v2.0.0** instead, which allows VMs to be replaced when templates are updated.

## Overview

This module deploys vSphere Virtual Machines with **template lifecycle protection**, making it ideal for:

- 🐾 **Long-lived VMs** (pets) - Databases, stateful applications, legacy systems
- 🔒 **Stable infrastructure** - VMs that should never be accidentally replaced
- 📌 **Version-pinned workloads** - Systems that must stay on specific OS versions

### Key Behavior (v1.6.0)

**Template Lifecycle Protection:**
- ✅ VMs are **NOT replaced** when source templates are updated or deleted
- ✅ Can run `terraform plan` even after templates are cleaned up from vSphere
- ✅ Template-derived properties (`guest_id`, `scsi_type`, `firmware`) are ignored in lifecycle
- ✅ VMs remain stable across Packer template rotations

**When Template Updates Are Needed:**
```bash
# To explicitly update a VM to a new template (rare for pets):
terraform apply -replace="module.my_vm.vsphere_virtual_machine.this"
```

## Quick Start

### Basic Usage

```hcl
module "database_server" {
  source  = "app.terraform.io/your-org/virtual-machine/vsphere"
  version = "1.6.0"  # Pets version

  hostname          = "prod-db-01"
  datacenter        = "Datacenter"
  cluster           = "Production"
  primary_datastore = "datastore1"

  template = "rhel-9-template"
  num_cpus = 4
  memory   = 8192

  networks = {
    "VM Network" = "10.0.1.10/24"
  }
}
```

### With HCP Packer Integration

```hcl
data "hcp_packer_artifact" "rhel9" {
  bucket_name  = "base-rhel-9"
  channel_name = "latest"
  platform     = "vsphere"
  region       = "Datacenter"
}

module "app_server" {
  source  = "app.terraform.io/your-org/virtual-machine/vsphere"
  version = "1.6.0"

  hostname = "app-server-01"
  template = data.hcp_packer_artifact.rhel9.external_identifier

  datacenter        = "Datacenter"
  cluster           = "Production"
  primary_datastore = "datastore1"

  num_cpus = 2
  memory   = 4096

  networks = {
    "VM Network" = "dhcp"
  }
}
```

**Important:** When old Packer templates are deleted:
1. The VM continues running (not affected)
2. `terraform plan` with `-refresh=false` will work fine
3. VM will never be replaced due to missing template

## Handling Deleted Templates

When your HCP Packer cleanup process deletes old templates:

### Option 1: Disable Refresh (Recommended for Pets)

**In Terraform Cloud workspace settings:**
- Add CLI argument: `-refresh=false`

**Or via variable:**
```hcl
# In workspace configuration
TF_CLI_ARGS_plan = "-refresh=false"
```

### Option 2: Temporarily Point to Valid Template

```hcl
# If you must run with refresh enabled, point to any valid template
module "pet_vm" {
  source   = "..."
  template = "rhel-9-latest"  # Any existing template (just for state refresh)

  # VM won't be replaced thanks to lifecycle protection
}
```

## Key Features

### Automatic Hostname Generation

If you don't provide a hostname, one will be generated:

```hcl
module "vm" {
  source = "..."
  # hostname not specified - will be generated like "camel-1234"

  datacenter = "Datacenter"
  cluster    = "Production"
  # ...
}
```

### Network Configuration

Supports both static IP and DHCP:

```hcl
networks = {
  "Production Network" = "10.0.1.50/24"  # Static IP
  "Backup Network"     = "dhcp"           # DHCP
}
```

### Guest OS Customization

Automatically detects OS type from template and applies appropriate customization:

```hcl
# For Linux VMs
domain          = "example.com"
dns_server_list = ["8.8.8.8", "8.8.4.4"]
gateway         = "10.0.1.1"

# For Windows VMs
admin_password        = var.admin_password
ad_domain             = "corp.example.com"
domain_admin_user     = "admin@corp.example.com"
domain_admin_password = var.domain_admin_password
```

### Cloud-Init Support

Pass userdata for cloud-init configuration:

```hcl
userdata = templatefile("${path.module}/cloud-init.yaml", {
  hostname = "my-server"
})
```

## Template Lifecycle Protection Details

### What Gets Protected

The following properties are in `lifecycle.ignore_changes`:

| Property | Why Protected |
|----------|--------------|
| `annotation` | Creation timestamp changes on every plan |
| `extra_config` | Cloud-init metadata shouldn't trigger replacement |
| `clone` | Template reference shouldn't cause replacement |
| `guest_id` | OS type derived from template |
| `scsi_type` | SCSI controller type from template |
| `firmware` | BIOS/EFI setting from template |

### What Still Triggers Replacement

Changes to these properties **will** cause VM replacement:
- `hostname` / `name`
- `num_cpus`
- `memory`
- `datacenter`
- `cluster`
- `primary_datastore`
- Network configuration

## Inputs

### Required

| Name | Type | Description |
|------|------|-------------|
| `datacenter` | `string` | vSphere datacenter name |
| `networks` | `map(string)` | Network mappings (name → IP or "dhcp") |

### Common Optional

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `hostname` | `string` | `null` | VM hostname (auto-generated if not provided) |
| `template` | `string` | `""` | Source template name |
| `cluster` | `string` | `""` | vSphere cluster (required if no resource_pool) |
| `resource_pool` | `string` | `""` | Resource pool path |
| `primary_datastore` | `string` | `""` | Datastore name (use this or datastore_cluster) |
| `primary_datastore_cluster` | `string` | `""` | Datastore cluster name |
| `num_cpus` | `number` | `2` | Number of virtual CPUs |
| `memory` | `number` | `2048` | Memory in MB |
| `disk_0_size` | `number` | `40` | Primary disk size in GB |
| `folder_path` | `string` | `""` | VM folder path |

### Network Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `domain` | `string` | `""` | DNS domain |
| `gateway` | `string` | `""` | Default gateway IP |
| `dns_server_list` | `list(string)` | `[]` | DNS server IPs |
| `dns_suffix_list` | `list(string)` | `[]` | DNS search suffixes |

### Windows-Specific

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `admin_password` | `string` | `""` | Local administrator password |
| `workgroup` | `string` | `""` | Windows workgroup |
| `ad_domain` | `string` | `""` | Active Directory domain to join |
| `domain_admin_user` | `string` | `""` | Domain admin username |
| `domain_admin_password` | `string` | `""` | Domain admin password |

### Advanced

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `tags` | `map(string)` | `{}` | vSphere tags (category → tag name) |
| `userdata` | `string` | `""` | Cloud-init userdata |
| `metadata` | `string` | `""` | Cloud-init metadata |
| `extra_disks` | `list(map(string))` | `[]` | Additional disks configuration |
| `enable_customization` | `bool` | `true` | Enable guest OS customization |

## Outputs

| Name | Description |
|------|-------------|
| `virtual_machine_id` | vSphere VM ID |
| `virtual_machine_name` | VM hostname |
| `ip_address` | Primary IP address |
| `guest_id` | Guest OS identifier |

## Version Comparison

| Version | Type | Template Changes | Use Case | When to Use |
|---------|------|-----------------|----------|-------------|
| **v1.6.0** (this) | 🐾 **Pets** | Protected - VMs never replaced | Databases, stateful apps | Long-lived infrastructure |
| **v2.0.0** | 🐄 **Cattle** | Triggers replacement | Immutable infrastructure | Web servers, auto-scaling |

## Migration Guide

### Upgrading from v1.5.x to v1.6.0

No breaking changes! Simply update the version:

```hcl
module "my_vm" {
  source  = "app.terraform.io/your-org/virtual-machine/vsphere"
  version = "1.6.0"  # Was 1.5.2 or earlier

  # All existing inputs remain the same
}
```

Run `terraform plan` - should show no changes.

### Moving to v2.0.0 (Cattle)

If you want cattle behavior (replacements on template updates):

```hcl
module "my_vm" {
  source  = "app.terraform.io/your-org/virtual-machine/vsphere"
  version = "2.0.0"  # Cattle version

  # Same inputs
}
```

**Note:** Changing versions won't replace existing VMs. The version only affects behavior for future template changes.

## Documentation

- 📘 **[Template Lifecycle Guide](./TEMPLATE_LIFECYCLE.md)** - Detailed template management docs
- 📁 **[Examples](./examples/)** - Complete working examples
- 🧪 **[Tests](./tests/)** - Terraform test configurations

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5 |
| vSphere Provider | >= 2.6 |

## License

This module is licensed under the Mozilla Public License 2.0.

## Support

For issues, questions, or contributions:
- Report issues in your organization's issue tracker
- See [TEMPLATE_LIFECYCLE.md](./TEMPLATE_LIFECYCLE.md) for troubleshooting

---

**Remember:** This is the **PETS version (v1.6.0)** - VMs are protected from template changes. Use **v2.0.0** for cattle behavior.
