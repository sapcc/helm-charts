<SecurityPolicies xmlns="urn:mace:shibboleth:3.0:native:sp:config">

    <!-- [FIX SP-01] validate="true" enables XML schema validation of incoming
         SAML messages. With validate="false" (package default), malformed SAML
         messages are accepted without structural checks, increasing the attack
         surface. BSI TR-03116-4 requires strict input validation. -->
    <Policy id="default" validate="true">
        <PolicyRule type="MessageFlow" checkReplay="true" expires="60"/>
        <PolicyRule type="Conditions">
            <PolicyRule type="Audience"/>
        </PolicyRule>
        <PolicyRule type="ClientCertAuth" errorFatal="true"/>
        <PolicyRule type="XMLSigning" errorFatal="true"/>
        <PolicyRule type="SimpleSigning" errorFatal="true"/>
    </Policy>

    <Policy id="blockUnsolicited" validate="false">
        <PolicyRule type="MessageFlow" blockUnsolicited="true" checkReplay="true" expires="60"/>
        <PolicyRule type="Conditions">
            <PolicyRule type="Audience"/>
        </PolicyRule>
        <PolicyRule type="ClientCertAuth" errorFatal="true"/>
        <PolicyRule type="XMLSigning" errorFatal="true"/>
        <PolicyRule type="SimpleSigning" errorFatal="true"/>
        <PolicyRule type="Bearer" blockUnsolicited="true"/>
    </Policy>

    <Policy id="entity-attributes">
        <PolicyRule type="Conditions"/>
        <PolicyRule type="XMLSigning" errorFatal="true"/>
    </Policy>

    <!-- Disables known weak algorithms. -->
    <ExcludedAlgorithms excludeDefaults="true"/>

</SecurityPolicies>
