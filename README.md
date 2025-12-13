# vSphere Virtual Machine - v2.0.0 (Cattle Version)

> **⚠️ Important:** This is the **CATTLE version** of the module. VMs created with this version **will be replaced** when templates are updated.
>
> 🐾 **Looking for the PETS version?** Use **v1.6.0** instead, which protects VMs from template changes.

## Overview

This module deploys vSphere Virtual Machines with **automatic template updates**, making it ideal for:

- 🐄 **Immutable infrastructure** (cattle) - Web servers, application servers, containerized workloads
- 🔄 **Auto-scaling workloads** - VMs that should update when templates change
- 🚀 **CI/CD pipelines** - Development and staging environments

### Key Behavior (v2.0.0)

**Automatic Template Updates:**
- ✅ VMs are **automatically replaced** when source templates are updated
- ✅ Ensures all VMs run the latest approved template version
- ✅ Template-derived properties (`guest_id`, `scsi_type`, `firmware`) trigger replacement
- ✅ Integrates seamlessly with HCP Packer template rotations

**How It Works:**
When your HCP Packer builds a new template and you update the template reference:
```hcl
template = data.hcp_packer_artifact.latest.external_identifier  # Points to new template
```

Next `terraform apply` → VM will be replaced with the new template ✅

## Quick Start

### Basic Usage

```hcl
module "web_server" {
  source  = "app.terraform.io/your-org/virtual-machine/vsphere"
  version = "2.0.0"  # Cattle version

  hostname          = "web-server-01"
  datacenter        = "Datacenter"
  cluster           = "Production"
  primary_datastore = "datastore1"

  template = "ubuntu-22.04-template"
  num_cpus = 2
  memory   = 4096

  networks = {
    "VM Network" = "dhcp"
  }
}
```

### With HCP Packer Integration

```hcl
data "hcp_packer_artifact" "ubuntu" {
  bucket_name  = "base-ubuntu-2204"
  channel_name = "latest"  # Always uses latest template
  platform     = "vsphere"
  region       = "Datacenter"
}

module "api_server" {
  source  = "app.terraform.io/your-org/virtual-machine/vsphere"
  version = "2.0.0"

  hostname = "api-server-01"
  template = data.hcp_packer_artifact.ubuntu.external_identifier

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

**Automatic Updates:** When HCP Packer builds a new template:
1. `data.hcp_packer_artifact.ubuntu` automatically points to new template
2. Next `terraform apply` → VM is replaced with latest template ✅
3. Old template can be safely deleted from vSphere

## Handling Template Updates

### Automatic Updates with HCP Packer

When using HCP Packer's `latest` channel, updates are automatic:

```hcl
data "hcp_packer_artifact" "ubuntu" {
  bucket_name  = "base-ubuntu-2204"
  channel_name = "latest"  # Automatically tracks latest
  # ...
}
```

**Workflow:**
1. HCP Packer builds new template
2. `latest` channel automatically points to new build
3. Next `terraform plan` shows replacement
4. `terraform apply` replaces VM with new template

### Controlled Updates with Iterations

For more control, use specific iterations:

```hcl
data "hcp_packer_artifact" "ubuntu" {
  bucket_name   = "base-ubuntu-2204"
  iteration_id  = "01HQXYZ..."  # Specific iteration
  # ...
}
```

**Workflow:**
1. Test new template in dev/staging
2. Manually update `iteration_id` when ready
3. `terraform apply` rolls out new template

### Deleted Templates

If a template is deleted before replacement:
- ❌ `terraform plan` will fail (template not found)
- ✅ **Solution:** Update template reference to valid template:

```hcl
# Update to any valid template
template = data.hcp_packer_artifact.ubuntu.external_identifier
```

Run `terraform apply` → VM replaced with new template ✅

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

## Template Lifecycle Details

### What Triggers Replacement (Cattle Behavior)

Changes to these properties **will** cause VM replacement:

| Property | Source | Why It Triggers Replacement |
|----------|--------|---------------------------|
| `hostname` / `name` | Direct input | VM identity change |
| `template` | HCP Packer / direct | **Template updated** |
| `guest_id` | Template | OS type changed in new template |
| `scsi_type` | Template | Storage controller changed |
| `firmware` | Template | BIOS/EFI changed |
| `num_cpus` | Direct input | Resource change |
| `memory` | Direct input | Resource change |
| `datacenter` | Direct input | Location change |
| `cluster` | Direct input | Compute resource change |
| `primary_datastore` | Direct input | Storage change |
| Network configuration | Direct input | Network topology change |

### What Gets Ignored (Won't Trigger Replacement)

The following properties are in `lifecycle.ignore_changes`:

| Property | Why Ignored |
|----------|------------|
| `annotation` | Creation timestamp changes on every plan |
| `extra_config` | Cloud-init metadata shouldn't trigger replacement |
| `ept_rvi_mode` | CPU virtualization setting (managed by vSphere) |
| `hv_mode` | Hypervisor mode (managed by vSphere) |

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
| **v1.6.0** | 🐾 **Pets** | Protected - VMs never replaced | Databases, stateful apps | Long-lived infrastructure |
| **v2.0.0** (this) | 🐄 **Cattle** | Triggers replacement | Immutable infrastructure | Web servers, auto-scaling |

## Migration Guide

### Upgrading from v1.5.x to v2.0.0

No breaking changes! Simply update the version:

```hcl
module "my_vm" {
  source  = "app.terraform.io/your-org/virtual-machine/vsphere"
  version = "2.0.0"  # Was 1.5.2 or earlier

  # All existing inputs remain the same
}
```

Run `terraform plan` - should show no changes (unless template has changed).

### Downgrading to v1.6.0 (Pets)

If you want pets behavior (protection from template updates):

```hcl
module "my_vm" {
  source  = "app.terraform.io/your-org/virtual-machine/vsphere"
  version = "1.6.0"  # Pets version

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

**Remember:** This is the **CATTLE version (v2.0.0)** - VMs will be replaced when templates change. Use **v1.6.0** for pets behavior (protection from template changes).
