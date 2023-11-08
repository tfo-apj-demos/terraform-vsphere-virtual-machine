data "vsphere_compute_cluster" "this" {
  for_each      = var.cluster != "" ? toset([var.cluster]) : toset([])
  name          = each.value
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_content_library" "this" {
  for_each = var.content_library_name != "" ? toset([var.content_library_name]) : toset([])
  name     = each.value
}

data "vsphere_content_library_item" "this" {
  for_each   = var.content_library_name != "" ? toset([var.template]) : toset([])
  name       = each.value
  library_id = data.vsphere_content_library.this[var.content_library_name].id
  type       = var.content_library_item_type
}

data "vsphere_datacenter" "this" {
  name = var.datacenter
}

data "vsphere_datastore" "this" {
  for_each      = var.primary_datastore != "" ? toset([var.primary_datastore]) : toset([])
  name          = each.value
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_datastore_cluster" "this" {
  for_each      = var.primary_datastore_cluster != "" ? toset([var.primary_datastore_cluster]) : toset([])
  name          = each.value
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_host" "this" {
  for_each      = toset(var.hosts)
  name          = each.value
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_network" "this" {
  for_each      = toset(keys(var.networks))
  name          = each.value
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_resource_pool" "this" {
  for_each      = var.resource_pool != "" ? toset([var.resource_pool]) : toset([])
  name          = each.value
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_storage_policy" "this" {
  for_each = toset(var.storage_policies)
  name     = each.value
}

data "vsphere_tag_category" "this" {
  for_each = toset(var.tag_categories)
  name     = each.value
}

data "vsphere_virtual_machine" "this" {
  for_each      = var.template != "" ? toset([var.template]) : toset([])
  name          = each.value
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_vmfs_disks" "this" {
  for_each       = toset(var.disks)
  host_system_id = each.value["host_id"]
  rescan         = true
  filter         = each.value["filter"]
}

module "tags" {
  for_each = var.tags
  source = "./modules/tags"

  tag_category_name = each.key
  tag_name = each.value

}