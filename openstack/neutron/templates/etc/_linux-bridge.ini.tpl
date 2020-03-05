[DEFAULT]
interface_driver = linuxbridge

# Disable Security Group for linux-bridge to increase buildup performance
[SECURITYGROUP]
firewall_driver = noop
