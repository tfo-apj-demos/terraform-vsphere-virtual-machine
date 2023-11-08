# data "hcp_packer_image" "base-ubuntu-2204" {
#   bucket_name     = "base-ubuntu-2204"
#   channel         = "latest"
#   cloud_provider  = "vsphere"
#   region          = "Datacenter"
# }

module "vm" {
  source = "../.."

  hostname          = var.hostname
  datacenter        = var.datacenter
  cluster           = var.cluster
  primary_datastore = var.primary_datastore
  folder_path       = var.folder_path
  networks = {
    "seg-general" : "dhcp"
  }
  #template = data.hcp_packer_image.base-ubuntu-2204.cloud_image_id
  template = var.vsphere_template_name

  userdata = templatefile("${path.module}/templates/userdata.yaml.tmpl", {
    custom_text = var.custom_text
    hostname    = var.hostname
  })

  metadata = templatefile("${path.module}/templates/metadata.yaml.tmpl", {
    dhcp     = true
    hostname = var.hostname
  })

  vsphere_user     = var.vsphere_user
  vsphere_password = var.vsphere_password
  vsphere_server   = var.vsphere_server
}