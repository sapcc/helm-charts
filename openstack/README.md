# Openstack Charts

Charts required for Openstack as well as dependent or related services.

## Requirements

Network and Hypervisor nodes need to be tainted.

```
kubectl taint node network0 species=network:NoSchedule
kubectl taint node network1 species=network:NoSchedule
kubectl taint node minion1  species=hypervisor:NoSchedule
```

Neutron and KVM could still be scheduled to any node. We need to confine
KVM pods to the hyperivsors and neutron agents to their dedicated network
nodes. 

Therefore, the nodes also need to be labeled.

```
kubectl label network0 species=network
kubectl label minion1  species=hypervisor
````
