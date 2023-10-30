terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.49.2"
    }
  }
}

provider "tfe" {
  organization = var.organization
}
