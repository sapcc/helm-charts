- name: "prod"
  displayName: "Prod"
  matchers:
    region: "^(?!qa-de-).*"
- name: "prod-qa"
  displayName: "Prod + QA"
  matchers:
    region: "^(?!qa-de-(?!1$)\\d+).*"
- name: "labs"
  displayName: "Labs"
  matchers:
    region: "^qa-de-(?!1$)\\d+"
- name: "all"
  displayName: "All"
  matchers:
    region: ".*"