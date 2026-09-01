locals {
  subnet_name = "${module.naming.subnet.name_unique}-1"
  tags = {
    environment     = "Demo"
    ServiceWorkload = "Azure Virtual Desktop"
  }
}
