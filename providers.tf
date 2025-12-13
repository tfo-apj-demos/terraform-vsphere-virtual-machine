terraform {
  required_providers {
    vsphere = {
      #source  = "hashicorp/vsphere"
      source = "vmware/vsphere"
      version = "~> 2"
    }
  }
}

provider "vsphere" {
}