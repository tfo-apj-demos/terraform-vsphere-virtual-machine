output "virtual_machine_id" {
  value = vsphere_virtual_machine.this.id
}

output "vsphere_compute_cluster_id" {
  value = data.vsphere_compute_cluster.this[var.cluster].id
}

output "virtual_machine_name" {
  value = local.hostname
}

output "ip_address" {
  value = vsphere_virtual_machine.this.default_ip_address
}

output "guest_id" {
  value = vsphere_virtual_machine.this.guest_id
}

# give me an output of the power state of the VM
output "power_state" {
  value = vsphere_virtual_machine.this.power_state
}