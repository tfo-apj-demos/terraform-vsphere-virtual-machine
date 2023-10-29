data "hcp_packer_image" "base-ubuntu-2204" {
  bucket_name     = "base-ubuntu-2204"
  channel         = "latest"
  cloud_provider  = "vsphere"
  region          = "Datacenter"
}

module "vm" {
  source = "../.."

  hostname          = "peppa-pig"
  datacenter        = "Datacenter"
  cluster           = "cluster"
  primary_datastore = "vsanDatastore"
  folder_path       = "Datacenter/vm/demo workloads"
  networks = {
    "seg-general" : "dhcp"
  }
  template = data.hcp_packer_image.base-ubuntu-2204.cloud_image_id
  
  userdata = templatefile("${path.module}/templates/userdata.yaml.tmpl", {
    custom_text = "some text to be rendered"
    hostname = "peppa-pig"
  })
  metadata = templatefile("${path.module}/templates/metadata.yaml.tmpl", {
    dhcp = true
    hostname = "peppa-pig"
  })
}

output "machine_ip" {
  value = module.vm.ip_address
}
