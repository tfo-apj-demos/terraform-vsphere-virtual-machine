data "hcp_packer_image" "base-ubuntu-2204" {
  bucket_name     = "base-ubuntu-2204"
  channel         = "latest"
  cloud_provider  = "vsphere"
  region          = "Datacenter"
}

resource "tfe_agent_pool" "this" {
  name         = "vsphere_agent_pool"
  organization_scoped = false
}

resource "tfe_agent_token" "this" {
  agent_pool_id = tfe_agent_pool.this.id
  description   = "agent token for vsphere environment"
}

module "vm" {
  source = "../.."

  hostname          = "gary"
  datacenter        = "Datacenter"
  cluster           = "cluster"
  primary_datastore = "vsanDatastore"
  folder_path       = "demo workloads"
  networks = {
    "seg-general" : "dhcp"
  }
  template = data.hcp_packer_image.base-ubuntu-2204.cloud_image_id
  
  userdata = templatefile("${path.module}/templates/userdata.yaml.tmpl", {
    agent_token = tfe_agent_token.this.token
    agent_name = "gary"
  })

  # metadata = templatefile("${path.module}/templates/metadata.yaml.tmpl", {
  #   hostname = "gary"
  # })
}

output "machine_ip" {
  value = module.vm.ip_address
}
