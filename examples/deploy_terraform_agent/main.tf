data "hcp_packer_image" "base-ubuntu-2204" {
  bucket_name    = "base-ubuntu-2204"
  channel        = "latest"
  cloud_provider = "vsphere"
  region         = var.datacenter
}

resource "tfe_agent_pool" "this" {
  name                = "vsphere_agent_pool"
  organization_scoped = false
}

resource "tfe_agent_token" "this" {
  agent_pool_id = tfe_agent_pool.this.id
  description   = "agent token for vsphere environment"
}

module "vm" {
  source = "../.."

  hostname          = var.hostname
  datacenter        = var.datacenter
  cluster           = var.cluster
  primary_datastore = var.primary_datastore
  folder_path       = var.folder_path
  networks          = var.networks
  template          = data.hcp_packer_image.base-ubuntu-2204.cloud_image_id

  userdata = templatefile("${path.module}/templates/userdata.yaml.tmpl", {
    agent_token = tfe_agent_token.this.token
    agent_name  = var.hostname
  })

  # metadata = templatefile("${path.module}/templates/metadata.yaml.tmpl", {
  #   hostname = var.hostname
  # })
}
