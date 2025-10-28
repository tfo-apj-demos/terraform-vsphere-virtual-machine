terraform {
  required_providers {
    vsphere = {
      #source  = "hashicorp/vsphere"
      source = "vmware/vsphere"
      version = "~> 2"
    }
  }
}