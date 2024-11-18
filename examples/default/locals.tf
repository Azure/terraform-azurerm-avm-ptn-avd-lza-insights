locals {
    registration_token = azurerm_virtual_desktop_host_pool_registration_info.registrationinfo.token
    tags = {
    environment        = "Demo"
    "Owner.Email"        = "jensheerin@microsoft.com"
    ServiceWorkload    = "Azure Virtual Desktop"
    CreationTimeUTC    = timestamp()
}
}
