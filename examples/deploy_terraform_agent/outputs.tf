output "machine_ip" {
  description = "The IP address of the provisioned VM."
  value       = module.vm.ip_address
}

output "agent_pool_id" {
  description = "The ID of the Terraform Cloud agent pool."
  value       = tfe_agent_pool.this.id
}