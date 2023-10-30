variable "vsphere_user" {
  description = "vSphere username"
  type        = string
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  sensitive   = true
}

variable "vsphere_server" {
  description = "vSphere server address"
  type        = string
}

variable "vsphere_template_name" {
  description = "The name of the vSphere template to use for VM creation."
  type        = string
  default     = "base-ubuntu-2204-20231029230706"
}

variable "hostname" {
  description = "The hostname for the VM."
  default     = "aaron-dev-01"
}

variable "datacenter" {
  description = "The vSphere datacenter."
  default     = "Datacenter"
}

variable "cluster" {
  description = "The vSphere cluster."
  default     = "cluster"
}

variable "primary_datastore" {
  description = "The primary datastore."
  default     = "vsanDatastore"
}

variable "folder_path" {
  description = "The path to the VM folder."
  default     = "Datacenter/vm/demo workloads"
}

variable "custom_text" {
  description = "Custom text to be rendered in userdata."
  default     = "some text to be rendered"
}