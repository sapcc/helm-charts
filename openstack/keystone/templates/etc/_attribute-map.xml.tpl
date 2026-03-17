{{- define "keystone.attribute-map.xml" -}}
<Attributes xmlns="urn:mace:shibboleth:2.0:attribute-map"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

    <!--
      SAML attribute-to-environment-variable mapping for Keystone federation.
      Keystone's Mapped auth plugin reads REMOTE_USER from the environment.
      mod_shib populates these env vars from the SAML assertion attributes.
    -->

    <!-- Standard NameID mapping to REMOTE_USER -->
    <Attribute name="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
        id="REMOTE_USER"/>
    <Attribute name="urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
        id="REMOTE_USER"/>
    <Attribute name="urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
        id="REMOTE_USER"/>

    <!-- eduPerson attributes (common in enterprise/academic IdPs) -->
    <Attribute name="urn:oid:1.3.6.1.4.1.5923.1.1.1.6" id="eppn">
        <AttributeDecoder xsi:type="ScopedAttributeDecoder"/>
    </Attribute>
    <Attribute name="urn:oid:1.3.6.1.4.1.5923.1.1.1.7" id="entitlement"/>
    <Attribute name="urn:oid:1.3.6.1.4.1.5923.1.1.1.9" id="affiliation">
        <AttributeDecoder xsi:type="ScopedAttributeDecoder" caseSensitive="false"/>
    </Attribute>

    <!-- Standard naming attributes -->
    <Attribute name="urn:oid:2.5.4.3" id="cn"/>
    <Attribute name="urn:oid:2.5.4.4" id="sn"/>
    <Attribute name="urn:oid:2.5.4.42" id="givenName"/>
    <Attribute name="urn:oid:0.9.2342.19200300.100.1.3" id="mail"/>
    <Attribute name="urn:oid:2.16.840.1.113730.3.1.241" id="displayName"/>

    <!-- SAML 2.0 Subject Identifier attributes -->
    <Attribute name="urn:oasis:names:tc:SAML:attribute:subject-id" id="subject-id">
        <AttributeDecoder xsi:type="ScopedAttributeDecoder" caseSensitive="false"/>
    </Attribute>
    <Attribute name="urn:oasis:names:tc:SAML:attribute:pairwise-id" id="pairwise-id">
        <AttributeDecoder xsi:type="ScopedAttributeDecoder" caseSensitive="false"/>
    </Attribute>

    <!-- OpenStack-specific attributes (if IdP sends them) -->
    <Attribute name="openstack_user" id="openstack_user"/>
    <Attribute name="openstack_roles" id="openstack_roles"/>
    <Attribute name="openstack_project" id="openstack_project"/>
    <Attribute name="openstack_user_domain" id="openstack_user_domain"/>
    <Attribute name="openstack_project_domain" id="openstack_project_domain"/>
    <Attribute name="openstack_groups" id="openstack_groups"/>

</Attributes>
{{- end -}}
