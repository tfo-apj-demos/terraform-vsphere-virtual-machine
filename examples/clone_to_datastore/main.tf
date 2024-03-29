data "hcp_packer_image" "base-ubuntu-2204" {
  bucket_name     = "base-ubuntu-2204"
  channel         = "latest"
  cloud_provider  = "vsphere"
  region          = "Datacenter"
}

module "vm" {
  source = "../.."

  hostname          = "bluey"
  datacenter        = "Datacenter"
  cluster           = "cluster"
  primary_datastore = "vsanDatastore"
  folder_path       = "Datacenter/vm/demo workloads"
  networks = {
    "seg-general" : "dhcp"
  }
  template = data.hcp_packer_image.base-ubuntu-2204.cloud_image_id
  
  metadata = templatefile("${path.module}/templates/metadata.yaml.tmpl", {
    dhcp = true
    hostname = "bluey"
  })
}