output "machine_ips" {
  description = "The IP addresses of the provisioned VMs."
  value       = { for key, vm_instance in module.vm : key => vm_instance.ip_address }
}

output "agent_pool_id" {
  description = "The ID of the Terraform Cloud agent pool."
  value       = tfe_agent_pool.this.id
}
