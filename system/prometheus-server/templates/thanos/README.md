Thanos
------

[Thanos](https://github.com/improbable-eng/thanos) ready for SAP Converged Cloud Enterprise Edition.  
Comes with OpenStack Swift storage backend configuration, OpenStackSeed for Swift, etc. .

## Configuration

Minimal configuration for Thanos@SAP Converged Cloud Enterprise Edition:

```
# How long metrics are retained. 
# For Thanos you want something like 1y.
retentionTime: <retention>

# In memory. Persist to Swift.
persistence:
  enabled: false

thanos:
  enabled: true
  swiftStorageConfig:
    authURL:          https://<keystone>/v3
    userName:         <userName>
    userDomainName:   <userDomainName>
    password:         <password>
    domainName:       <domainName>
    tenantName:       <tenantName>
    regionName:       <regionName>
    containerName:    <swiftContainerName>
```