locals {
  windows                     = var.template != "" ? length(regexall("^win", data.vsphere_virtual_machine.this[var.template].guest_id)) > 0 : null
  hostname                    = var.hostname != "" ? var.hostname : "${random_pet.this.id}-${random_integer.this.result}"
  size                        = data.vsphere_virtual_machine.this[var.template].disks[0].size

  metadata = <<EOH
local-hostname: ${local.hostname}
instance-id: ${local.hostname}
network:
  version: 2
  ethernets:
    ens192:
      dhcp4: true
EOH
}

resource "random_pet" "this" {
  length = 1
}

resource "random_integer" "this" {
  min = 1000
  max = 9999
}

resource "vsphere_virtual_machine" "this" {
  name             = local.hostname
  folder           = var.folder_path != "" ? var.folder_path : null
  resource_pool_id = var.resource_pool != "" ? data.vsphere_resource_pool.this[var.resource_pool].id : data.vsphere_compute_cluster.this[var.cluster].resource_pool_id
  tags             = var.tags != {} ? [for tag in module.tags : tag.tag_id] : null

  datastore_id         = var.primary_datastore != "" ? data.vsphere_datastore.this[var.primary_datastore].id : null
  datastore_cluster_id = var.primary_datastore_cluster != "" ? data.vsphere_datastore_cluster.this[var.primary_datastore_cluster].id : null

  num_cpus  = var.num_cpus
  memory    = var.memory
  guest_id  = var.template != "" ? data.vsphere_virtual_machine.this[var.template].guest_id : null
  scsi_type = var.template != "" ? data.vsphere_virtual_machine.this[var.template].scsi_type : null
  firmware  = var.template != "" ? data.vsphere_virtual_machine.this[var.template].firmware : null

  scsi_controller_count = length(var.extra_disks) + 1
  annotation            = "Created: ${formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())}"

  lifecycle {
    ignore_changes = [
      annotation,
      extra_config,
      clone
    ]
  }
  dynamic "network_interface" {
    for_each = var.networks
    content {
      network_id   = data.vsphere_network.this[network_interface.key].id
      adapter_type = var.network_adapter_type
    }
  }

  wait_for_guest_net_timeout = 120
  dynamic "disk" {
    for_each = var.template != "" ? [0] : []
    content {
      label            = "disk0"
      size             = var.disk_0_size #local.size
      eagerly_scrub    = data.vsphere_virtual_machine.this[var.template].disks[0].eagerly_scrub
      thin_provisioned = data.vsphere_virtual_machine.this[var.template].disks[0].thin_provisioned
    }
  }

  dynamic "disk" {
    for_each = var.extra_disks
    content {
      label        = format("disk-%d", index(var.extra_disks, disk.value) + 1)
      unit_number  = 15 * (index(var.extra_disks, disk.value) + 1) + index(var.extra_disks, disk.value) + 1
      attach       = true
      path         = disk.value["path"]
      disk_sharing = disk.value["disk_sharing"]
      datastore_id = data.vsphere_datastore.this[disk.value["datastore_id"]].id
    }
  }

  dynamic "cdrom" {
    for_each = var.cdroms
    content {
      client_device = cdrom.value.client_device
      datastore_id  = cdrom.value.datastore_id != "" ? data.vsphere_datastore.this[cdrom.value.datastore_id].id : null
      path          = cdrom.value.path
    }
  }

  dynamic "clone" {
    for_each = var.template != "" ? [0] : []
    content {
      template_uuid = data.vsphere_virtual_machine.this[var.template].id

      customize {
        dynamic "linux_options" {
          for_each = local.windows == false ? [0] : []
          content {
            host_name = local.hostname
            domain    = var.domain
          }
        }

        dynamic "windows_options" {
          for_each = local.windows == true ? [0] : []
          content {
            computer_name         = local.hostname
            admin_password        = var.admin_password
            workgroup             = var.workgroup != "" ? var.workgroup : null
            join_domain           = var.ad_domain != "" ? var.ad_domain : null
            domain_admin_user     = var.ad_domain != "" ? var.domain_admin_user : null
            domain_admin_password = var.ad_domain != "" ? var.domain_admin_password : null
          }
        }

        dynamic "network_interface" {
          for_each = var.networks
          iterator = network
          content {
            ipv4_address = lower(network.value) == "dhcp" ? null : split("/", network.value)[0]
            ipv4_netmask = lower(network.value) == "dhcp" ? null : split("/", network.value)[1]
          }
        }

        ipv4_gateway    = var.gateway
        dns_server_list = var.dns_server_list
        dns_suffix_list = var.dns_suffix_list
      }
    }
  }
  datacenter_id  = var.remote_ovf_url != "" || var.local_ovf_path != "" ? data.vsphere_datacenter.this.id : null
  host_system_id = length(var.hosts) == 0 ? null : data.vsphere_host.this[var.hosts[0]].id

  dynamic "ovf_deploy" {
    for_each = var.remote_ovf_url != "" || var.local_ovf_path != "" ? [0] : []
    content {
      local_ovf_path            = var.local_ovf_path != "" ? var.local_ovf_path : null
      remote_ovf_url            = var.remote_ovf_url != "" ? var.remote_ovf_url : null
      ip_allocation_policy      = var.ip_allocation_policy
      ip_protocol               = var.ip_protocol
      disk_provisioning         = var.disk_provisioning
      ovf_network_map           = { for k, v in var.ovf_network_map : k => data.vsphere_network.this[v].id }
      allow_unverified_ssl_cert = var.allow_unverified_ssl_cert
    }
  }

  dynamic "vapp" {
    for_each = var.remote_ovf_url != "" || var.local_ovf_path != "" ? [0] : []
    content {
      properties = merge(var.vapp_properties,
        {
          "guestinfo.dns"       = join(",", var.dns_server_list)
          "guestinfo.domain"    = var.domain
          "guestinfo.gateway"   = var.gateway
          "guestinfo.hostname"  = local.hostname
          "guestinfo.ipaddress" = lower(values(var.networks)[0]) == "dhcp" ? null : split("/", values(var.networks)[0])[0]
          "guestinfo.netmask"   = lower(values(var.networks)[0]) == "dhcp" ? null : split("/", values(var.networks)[0])[1]
          "guestinfo.ntp"       = join(",", var.ovf_ntp_servers)
          "guestinfo.password"  = var.ovf_password
          "guestinfo.ssh"       = var.ovf_enable_ssh
          "guestinfo.syslog"    = var.ovf_syslog_server
        }
      )
    }
  }

  extra_config = {
    "guestinfo.userdata"          = var.userdata != "" ? base64encode(var.userdata) : null
    "guestinfo.userdata.encoding" = var.userdata != "" ? "base64" : null
    "guestinfo.metadata"          = var.metadata != "" ? base64encode(var.metadata) : base64encode(local.metadata)
    "guestinfo.metadata.encoding" = "base64"
  }
}
