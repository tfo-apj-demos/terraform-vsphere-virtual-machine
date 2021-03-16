# vSphere Virtual Machine

This module has been written to make deployment of vSphere Virtual Machines a much easier affair than it would otherwise be!

The structure of the module has been optimised to allow you to get started with minimal inputs, but if you want to get down and dirty with specific configurations then you can do so.

The following code sample shows a quick and easy starting point.

```
module vsphere_machine {
  source = "github.com/terraform-vsphere-modules/terraform-vsphere-virtual-machine"

  datacenter                = "Core"
  cluster                   = "Management"
  primary_datastore_cluster = "Production"
  networks                  = {
    "VM Network":"10.0.3.8/24",
    "Backup":"dhcp"
  }
  template                  = "ubuntu-18.04-2020-06-13"
}
```

Based on your inputs, the appropriate data sources will be used to query your vSphere infrastructure.

The guest OS configuration/customisation uses dynamic blocks to egnerate the code based on the guest_id attribute of the source template.
Similarly, network configuration (static/dhcp) will be generated based on the keys/values you feed into the networks input.

If you don't provide a hostname, one will be generated for you using the random_pet and random_integer resources.
