# l3_agent.ini
[DEFAULT]
debug = {{.Values.debug}}

l3_agent_manager = neutron.agent.l3_agent.L3NATAgentWithStateReport
agent_mode = legacy
