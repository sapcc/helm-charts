- [Cerebro seed project](#cerebro-seed-project)
- [Folder structure](#folder-structure)

# Cerebro seed project
Contains project seed for generating a project on CC.

- Example project seed: [link](https://github.com/sapcc/helm-charts/blob/master/openstack/domain-seeds/templates/domain-ccadmin-seed.yaml)
- Quota definition: [link](https://github.com/sapcc/limes/blob/master/docs/operators/config.md)


# Folder structure
- `regions/$REGION/values/cerebro.yaml`: Region specific values such as technical user
- `templates/domain-ccadmin-seed.yaml`: Project seed for generating the project. Contains: 
  - Networking
  - Technical user and his roles
  - User groups to be assigned by the technical user on the fly
- `initial-quota.yaml`: Initial resource quotas for the generated project 
