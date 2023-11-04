# data "hcp_packer_image" "base-ubuntu-2204" {
#   bucket_name    = "base-ubuntu-2204"
#   channel        = "latest"
#   cloud_provider = "vsphere"
#   region         = var.datacenter
# }
locals {
  user_list = yamldecode(file("${path.module}/templates/users.yaml"))["users"]
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
  providers = {
    vsphere = vsphere
  }
  
  for_each = toset(local.user_list)

  source = "../.."

  vsphere_user      = var.vsphere_user
  vsphere_password  = var.vsphere_password
  vsphere_server    = var.vsphere_server
  hostname          = format("%s-tfc-agent", each.value) # This appends -tfc-agent to each username
  datacenter        = var.datacenter
  cluster           = var.cluster
  primary_datastore = var.primary_datastore
  folder_path       = var.folder_path
  networks          = var.networks
  template          = var.vsphere_template_name
  #template          = data.hcp_packer_image.base-ubuntu-2204.cloud_image_id

  userdata = templatefile("${path.module}/templates/userdata.yaml.tmpl", {
    agent_token = tfe_agent_token.this.token
    agent_name  = format("%s-tfc-agent", each.value) # Also append -tfc-agent for the agent_name
  })

  # metadata = templatefile("${path.module}/templates/metadata.yaml.tmpl", {
  #   hostname = format("%s-tfc-agent", each.value)
  # })
}