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
  for_each = toset(local.user_list)

  source = "../.."
  hostname          = format("%s-tfc-agent", each.value) # This appends -tfc-agent to each username
  datacenter        = var.datacenter
  cluster           = var.cluster
  primary_datastore = var.primary_datastore
  folder_path       = var.folder_path
  networks          = var.networks
  template          = var.vsphere_template_name

  userdata = templatefile("${path.module}/templates/userdata.yaml.tmpl", {
    agent_token = tfe_agent_token.this.token
    agent_name  = format("%s-tfc-agent", each.value) # Also append -tfc-agent for the agent_name
  })
}