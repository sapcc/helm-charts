{{- define "keystone.attribute-map.xml" -}}
<Attributes xmlns="urn:mace:shibboleth:2.0:attribute-map"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

    <!--
      SAML attribute-to-environment-variable mapping for Keystone federation.
      Keystone's Mapped auth plugin reads REMOTE_USER from the environment.
      mod_shib populates REMOTE_USER from whichever decoded attribute ID is
      listed first in the REMOTE_USER setting of ApplicationDefaults.
      Note: REMOTE_USER is a reserved name in Shibboleth and cannot be used
      as an attribute id directly.
    -->

    <!-- NameID extraction using NameIDAttributeDecoder.
         In Shibboleth SP 3, NameID is NOT a regular SAML attribute — it's a
         separate XML element. The NameIDAttributeDecoder extracts the NameID
         value and exposes it as a regular attribute that REMOTE_USER can use.
         formatter="$Name" extracts just the NameID value.
         The NameID format depends on the IdP configuration and cannot be
         deduced from IdP metadata. Add decoders for all formats the IdP
         might use. -->
    <Attribute name="urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified" id="unspecified-nameid">
        <AttributeDecoder xsi:type="NameIDAttributeDecoder" formatter="$Name"/>
    </Attribute>
    <Attribute name="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress" id="email-nameid">
        <AttributeDecoder xsi:type="NameIDAttributeDecoder" formatter="$Name"/>
    </Attribute>
    <Attribute name="urn:oasis:names:tc:SAML:2.0:nameid-format:persistent" id="persistent-id">
        <AttributeDecoder xsi:type="NameIDAttributeDecoder" formatter="$Name"/>
    </Attribute>
    <Attribute name="urn:oasis:names:tc:SAML:2.0:nameid-format:transient" id="transient-id">
        <AttributeDecoder xsi:type="NameIDAttributeDecoder" formatter="$Name"/>
    </Attribute>

    <!-- eduPerson attributes (common in enterprise/academic IdPs) -->
    <Attribute name="urn:oid:1.3.6.1.4.1.5923.1.1.1.6" id="eppn">
        <AttributeDecoder xsi:type="ScopedAttributeDecoder"/>
    </Attribute>
    <Attribute name="urn:oid:1.3.6.1.4.1.5923.1.1.1.7" id="entitlement"/>
    <Attribute name="urn:oid:1.3.6.1.4.1.5923.1.1.1.9" id="affiliation">
        <AttributeDecoder xsi:type="ScopedAttributeDecoder" caseSensitive="false"/>
    </Attribute>

    <!-- Standard naming attributes (OID format) -->
    <Attribute name="urn:oid:2.5.4.3" id="cn"/>
    <Attribute name="urn:oid:2.5.4.4" id="sn"/>
    <Attribute name="urn:oid:2.5.4.42" id="givenName"/>
    <Attribute name="urn:oid:0.9.2342.19200300.100.1.3" id="mail"/>
    <Attribute name="urn:oid:2.16.840.1.113730.3.1.241" id="displayName"/>

    <!-- ADFS / SAP IAS claim URI format -->
    <Attribute name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress" id="mail"/>
    <Attribute name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn" id="upn"/>
    <Attribute name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name" id="displayName"/>
    <Attribute name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname" id="givenName"/>
    <Attribute name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname" id="sn"/>

    <!-- SAP IAS plain-name attributes (sent with simple attribute names) -->
    <Attribute name="mail" id="mail"/>
    <Attribute name="first_name" id="givenName"/>
    <Attribute name="last_name" id="sn"/>
    <Attribute name="user_uuid" id="user_uuid"/>

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
