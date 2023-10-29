data "hcp_packer_image" "this" {
  bucket_name     = "base-ubuntu-2204"
  channel         = "latest"
  cloud_provider  = "vsphere"
  region          = "Datacenter"
}

module "vm" {
  source = "../../"
  count = 2

  datacenter        = "Datacenter"
  cluster           = "cluster"
  primary_datastore = "vsanDatastore"
  template          = data.hcp_packer_image.this.cloud_image_id
  folder_path       = "demo workloads"
  networks          = {
    "seg-general" : "dhcp"
  }
  extra_disks       = [
    {
      "path":vsphere_virtual_disk.this.vmdk_path
      "disk_sharing":"sharingMultiWriter"
      "datastore_id":vsphere_virtual_disk.this.datastore
    }
  ]

    metadata = templatefile("${path.module}/templates/metadata.yaml.tmpl", {
    dhcp = true
    hostname = "peppa-pig-${count.index}"
  })
}

resource "vsphere_virtual_disk" "this" {
  size       = 2
  vmdk_path  = "/shared_disk/module.vmdk"
  create_directories = true
  datacenter = "Datacenter"
  datastore  = "vsanDatastore"
  type       = "eagerZeroedThick"
}