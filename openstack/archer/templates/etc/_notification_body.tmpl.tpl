<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5; }
    .container { max-width: 600px; margin: 0 auto; background-color: #ffffff; }
    .headline { padding: 30px 30px 10px; }
    .headline h1 { font-size: 26px; color: #1a1a1a; margin: 0 0 5px; }
    .headline p { font-size: 14px; color: #666666; margin: 0; }
    .headline .internal { font-size: 11px; color: #999999; text-transform: uppercase; letter-spacing: 1px; margin-top: 8px; }
    .header { padding: 10px 20px 20px; text-align: center; }
    .header img { max-width: 100%; height: auto; }
    .content { padding: 10px 30px 20px; color: #333333; line-height: 1.6; }
    h2 { font-size: 16px; color: #333333; margin-top: 10px; margin-bottom: 8px; line-height: 1.4; }
    h2 .endpoint-id { font-size: 12px; font-weight: normal; color: #666666; }
    hr { border: none; border-top: 2px solid #cccccc; margin: 25px 0 25px; }
    .endpoint-list { list-style: decimal; padding: 0 0 0 20px; margin: 0; }
    .endpoint-list li { padding: 8px 0; }
    .endpoint-id { font-family: monospace; font-size: 13px; color: #666666; }
    .endpoint-prop { color: #666666; font-size: 13px; }
    .endpoint-props { border-collapse: collapse; margin-top: 4px; }
    .endpoint-props td { padding: 2px 0; vertical-align: top; font-size: 13px; color: #666666; }
    .endpoint-props td.label { padding-right: 12px; white-space: nowrap; }
    .footer { padding: 15px 30px; font-size: 12px; color: #666666; background-color: #f9f9f9; }
  </style>
</head>
<body>
  <div class="container">
    <div class="headline">
      <h1>Archer Endpoint Services{{ `{{- if eq .Type "digest" }}` }} Digest{{ `{{- end }}` }}</h1>
      <p>{{ `{{.TotalEndpoints}}` }} endpoint(s) awaiting approval across {{ `{{len .Services}}` }} service(s)</p>
      <p class="internal">INTERNAL</p>
    </div>
    <div class="header">
      <img src="data:image/png;base64,{{ .Files.Get "img/header.png" | b64enc }}" alt="Header">
    </div>
    <div class="content">
      <p>Dear Colleagues,</p>

      <p>One or more endpoints are awaiting your approval as the owner of the listed service(s) below.</p>

      <p>Please review each endpoint &mdash; in particular the consumer project &mdash; and approve only those you recognize and expect. Approval grants the consumer transparent network access to your service.</p>

      <p>You can approve or reject endpoints from the <a href="https://dashboard.{{ .Values.global.region }}.cloud.sap/">Endpoint Services dashboard</a> or via the <code>archerctl</code> CLI.</p>

      {{ `{{ range $i, $s := .Services -}}` }}
      <hr>
      <h2>Service: {{ `{{$s.Name}}` }}</h2>
      <table class="endpoint-props" role="presentation" cellspacing="0" cellpadding="0" border="0">
        <tr>
          <td class="label">ID:</td>
          <td><span class="endpoint-id">{{ `{{$s.ID}}` }}</span></td>
        </tr>
      </table>
      {{ `{{- if $s.Description }}` }}
      <p>{{ `{{$s.Description}}` }}</p>
      {{ `{{- end }}` }}

      <ul class="endpoint-list">
      {{ `{{ range $s.Endpoints -}}` }}
        <li>
          <strong>Endpoint{{ `{{if .Name}}` }}: {{ `{{.Name}}{{end}}` }}</strong>
          <table class="endpoint-props" role="presentation" cellspacing="0" cellpadding="0" border="0">
            <tr>
              <td class="label">ID:</td>
              <td><span class="endpoint-id">{{ `{{.ID}}` }}</span></td>
            </tr>
            <tr>
              <td class="label">Project:</td>
              <td><span class="endpoint-id">{{ `{{.ProjectID}}` }}</span></td>
            </tr>
            {{ `{{- if ne $.Type "immediate" }}` }}
            <tr>
              <td class="label">Pending for:</td>
              <td>{{ `{{since .CreatedAt}}` }}</td>
            </tr>
            {{ `{{- end }}` }}
          </table>
        </li>
      {{ `{{- end }}` }}
      </ul>
      {{ `{{- end }}` }}

    </div>
    <div class="footer">
      <p><a href="http://www.sap.com/copyright">Copyright/Trademark</a> | <a href="http://www.sap.com/about/legal/privacy.html">Privacy</a> | <a href="http://www.sap.com/about/legal/impressum.html">Impressum</a></p>
      <p>SAP SE, Dietmar-Hopp-Allee 16, 69190 Walldorf, Germany</p>
      <p>Pflichtangaben/Mandatory Disclosure Statements: <a href="http://www.sap.com/about/legal/impressum.html">http://www.sap.com/about/legal/impressum.html</a></p>
      <p>Diese E-Mail kann Betriebs- oder Gesch&auml;ftsgeheimnisse oder sonstige vertrauliche Informationen enthalten. Sollten Sie diese E-Mail irrt&uuml;mlich erhalten haben, ist Ihnen eine Kenntnisnahme des Inhalts, eine Vervielf&auml;ltigung oder Weitergabe der E-Mail ausdr&uuml;cklich untersagt. Bitte benachrichtigen Sie uns und vernichten Sie die empfangene E-Mail. Vielen Dank.</p>
      <p>This e-mail may contain trade secrets or privileged, undisclosed, or otherwise confidential information. If you have received this e-mail in error, you are hereby notified that any review, copying, or distribution of it is strictly prohibited. Please inform us immediately and destroy the original transmittal. Thank you for your cooperation.</p>
    </div>
  </div>
</body>
</html>
