<!doctype html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <meta xmlns:v="urn:schemas-microsoft-com:vml">
        <meta xmlns:o="urn:schemas-microsoft-com:office:office">
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
            table {
              border-collapse: collapse;
              width: 100%;
            }
            
            th, td {
              border: 1px solid;
              text-align: left;
              padding: 8px;
            }
            </style>
    </head>
    <body>
        <p><b>Dear SAP Cloud Infrastructure user</b>,</p>
        <p>the following commitments are {{ .condition }} for the
            following project:</p>
        <p>
            <ul>
                <li>Region: {{ .region }}</li>
                <li>Domain: {{"{{"}}  .DomainName {{"}}"}}</li>
                <li>Project: {{"{{"}} .ProjectName {{"}}"}}</li>
            </ul>
        </p>
        {{ .dashboardInfo }}

        <div style="overflow-x: auto;">
            <table>
                <tr style="background-color: #f2f2f2;">
                    <th>Creator</th>
                    <th>Amount</th>
                    <th>Duration</th>
                    <th>Date</th>
                    <th>Service</th>
                    <th>Resource</th>
                    <th>Zone</th>
                </tr>
                {{"{{"}}  range .Commitments {{"}}"}}
                <tr>
                    <td>{{"{{"}} .Commitment.CreatorName {{"}}"}}</td>
                    <td>{{"{{"}} .Commitment.Amount {{"}}"}}</td>
                    <td>{{"{{"}} .Commitment.Duration {{"}}"}}</td>
                    <td>{{"{{"}} .DateString {{"}}"}}</td>
                    <td>{{"{{"}} .Resource.ServiceType {{"}}"}}</td>
                    <td>{{"{{"}} .Resource.ResourceName {{"}}"}}</td>
                    <td>{{"{{"}} .Resource.AvailabilityZone {{"}}"}}</td>
                </tr>
                {{"{{"}}  end {{"}}"}}
            </table>
        </div>

        <p>
            <div>Thank you,</div>
            <div> The SAP Cloud Infrastructure Team</div>
        </p>
    </body>
</html>
