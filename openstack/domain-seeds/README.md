## Seeds for creating customer domains

**They should only contain the bare minimum to install the domain and take care of the domain driver configuration.**

Any service specific users, groups, projects or role assignments should be seeded from a corresponding **service seed** that refers to the domain-seed it enriches (requires it).

So in general: if a service requires a (new) role, it should also take care of seeding the role and any role-assignments that refer to this role.

Exception: (common) objects that are not directly related to a specific service or are related to a (external) service that is not deployed via helm can be included into the domain seeds.
 

### Sequence of seeding / deployment

1. the openstack-operator is deployed to k8s and introduces the openstackseed TPR type.
2. the keystone service is deployed and bootstraps the default domain and admin role.
3. the domain-seeds chart is deployed and seeds the customer domains with minimal content.
4. other (openstack) services are deployed and introduce their service (catalog entry with endpoints), add their service-user, add additional roles and enrich the previously seeded (customer) domains where required 


### Special case

**Multi-regional Designate/Keystone setup**

Only the following domains should be seeded:
- default
- cc3test
- ccadmin
- global

Check for **global.is_global_region** value equals **true** for such scenario. All other domain seeds will be ignored.
**Important** to set a correct kubernetes namespace where keystone will be deployed **(keystoneNamespace: 'monsoon3global', not 'monsoon3')**
