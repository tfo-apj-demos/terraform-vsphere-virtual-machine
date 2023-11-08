terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.49.2"
    }
    vsphere = {
      source = "hashicorp/vsphere"
      version = "2.5.1"
    }
  }
}

provider "tfe" {
  organization = var.organization
}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}