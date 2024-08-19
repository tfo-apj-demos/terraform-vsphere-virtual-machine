variable "cluster" {
  description = "The name of the cluster into which you want your workload provisioned. Must be set if resource_pool is not set."
  type        = string
  default     = ""
}

variable "content_library_name" {
  type    = string
  default = ""
}

variable "content_library_item_type" {
  type    = string
  default = "vm-template"
  validation {
    condition     = var.content_library_item_type == "ovf" || var.content_library_item_type == "iso" || var.content_library_item_type == "vm-template"
    error_message = "Must be one of ovf, iso, or vm-template."
  }
}

variable "custom_attributes" {
  description = "A list of custom attributes to assign to your vm."
  type        = list(string)
  default     = []
}

variable "datacenter" {
  description = "The name of the datacenter in which you want your workload provisioned."
  type        = string
}

variable "primary_datastore" {
  description = "The name of the datastore for the first disk to be placed. Must be set if primary_datastore_cluster is not used."
  type        = string
  default     = ""
}

variable "primary_datastore_cluster" {
  description = "The name of the datastore for the first disk to be placed. Must be set if primary_datastore is not used."
  type        = string
  default     = ""
}

variable "disks" {
  description = ""
  type        = list(map(string))
  default     = []
}

variable "cdroms" {
  description = "List of CDROM configurations"
  type = list(object({
    client_device = optional(bool)
    datastore_id  = optional(string)
    path          = optional(string)
  }))
  default = []
}

variable "hosts" {
  type    = list(string)
  default = []
}

variable "resource_pool" {
  description = "The name of the resource pool that you want your virtual machine deployed into. If not set, your machine will be placed in the default resource pool of the cluster."
  type        = string
  default     = ""
}

variable "storage_policies" {
  type    = list(string)
  default = []
}

variable "tag_categories" {
  type    = list(string)
  default = []
}

variable "template" {
  type    = string
  default = ""
}

variable "hostname" {
  type    = string
  default = ""
}

variable "num_cpus" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 2048
}

variable "scsi_type" {
  type    = string
  default = "pvscsi"
}

variable "network_adapter_type" {
  type    = string
  default = "vmxnet3"
}

variable "eagerly_scrub" {
  default = false
}

variable "thin_provisioned" {
  default = true
}

variable "domain" {
  type    = string
  default = ""
}

variable "gateway" {
  type    = string
  default = ""
}

variable "networks" {
  type    = map(string)
  default = {}
}

variable "dns_server_list" {
  default = []
}

variable "dns_suffix_list" {
  default = []
}

variable "admin_password" {
  type    = string
  default = ""
}

variable "workgroup" {
  type    = string
  default = ""
}

variable "ad_domain" {
  type    = string
  default = ""
}

variable "domain_admin_user" {
  type    = string
  default = ""
}

variable "domain_admin_password" {
  type    = string
  default = ""
}

variable "local_ovf_path" {
  type    = string
  default = ""
}
variable "remote_ovf_url" {
  type    = string
  default = ""
}
variable "ip_allocation_policy" {
  type    = string
  default = "STATIC_MANUAL"
}
variable "ip_protocol" {
  type    = string
  default = "IPV4"
}
variable "disk_provisioning" {
  type    = string
  default = "thin"
}
variable "ovf_network_map" {
  type    = map(any)
  default = {}
}

variable "allow_unverified_ssl_cert" {
  type    = bool
  default = true
}

variable "vapp_properties" {
  type    = map(any)
  default = {}
}

variable "ovf_ipaddress" {
  type    = string
  default = ""
}
variable "ovf_netmask" {
  type    = string
  default = ""
}
variable "ovf_ntp_servers" {
  type    = list(any)
  default = ["pool.ntp.org"]
}
variable "ovf_password" {
  type    = string
  default = "VMware123!"
}
variable "ovf_enable_ssh" {
  type    = string
  default = "false"
}
variable "ovf_syslog_server" {
  type    = string
  default = ""
}

variable "extra_disks" {
  type    = list(map(string))
  default = []
}

variable "disk_0_size" {
  default = 40
}

variable "userdata" {
  type    = string
  default = ""
}

variable "metadata" {
  type    = string
  default = ""
}

variable "folder_path" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}