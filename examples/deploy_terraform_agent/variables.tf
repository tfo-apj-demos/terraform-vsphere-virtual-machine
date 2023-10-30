variable "organization" {
  description = "The Terraform Cloud organization name."
  type        = string
}

variable "datacenter" {
  description = "The name of the vSphere datacenter."
  type        = string
}

variable "cluster" {
  description = "The vSphere cluster name."
  type        = string
}

variable "primary_datastore" {
  description = "The primary datastore for the VM."
  type        = string
}

variable "folder_path" {
  description = "The vSphere folder path for the VM."
  type        = string
  default     = "demo workloads"
}

variable "networks" {
  description = "A map of network configurations."
  type        = map(string)
  default = {
    "seg-general" = "dhcp"
  }
}

variable "hostname" {
  description = "The hostname for the VM."
  type        = string
  default     = "gary"
}

variable "vsphere_template_name" {
  description = "The name of the vSphere template to use for VM creation."
  type        = string
}

