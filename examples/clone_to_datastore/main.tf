module "terraform_agent" {
  source = "github.com/terraform-vsphere-modules/terraform-vsphere-virtual-machine"

  datacenter        = "Core"
  cluster           = "Management"
  primary_datastore = "hl-core-ds02"
  networks = {
    "VM Network" : "dhcp"
  }
  template = "ubuntu-18.04-packer-20210223073204"
}
