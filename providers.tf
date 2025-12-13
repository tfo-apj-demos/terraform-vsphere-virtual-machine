terraform {
  required_providers {
    vsphere = {
      source = "vmware/vsphere"
      version = "~> 2"
    }
  }
}

provider "vsphere" {
}