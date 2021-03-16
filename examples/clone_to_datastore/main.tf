module "terraform_agent" {
  source = "../../"

  datacenter        = "Core"
  cluster           = "Management"
  primary_datastore = "hl-core-ds02"
  networks = {
    "VM Network" : "dhcp"
  }
  template = "ubuntu-18.04-packer-20210223073204"
  num_cpus = 4
  memory   = 4096
}
