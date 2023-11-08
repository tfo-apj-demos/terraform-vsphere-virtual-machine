data "vsphere_tag_category" "this" {
  name = var.tag_category_name
}

data "vsphere_tag" "this" {
  name = var.tag_name
  category_id = data.vsphere_tag_category.this.id
}

output "tag_id" {
  value = data.vsphere_tag.this.id
}

variable "tag_name" {
  type = string
}

variable "tag_category_name" {
  type = string
}