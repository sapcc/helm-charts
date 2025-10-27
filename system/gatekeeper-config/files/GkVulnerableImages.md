This check finds containers whose image contains known vulnerabilities.

#### Where to find vulnerability reports?

Copy-paste the path part of the image (e.g. `keppel.eu-de-1.cloud.sap/ccloud/limes`) into your browser address bar.
This opens the image list for that repo in Elektra's Keppel UI. Find the relevant image (look for a vulnerability status
other than "Clean") and open its details view to find the vulnerabilities on the "Vulnerabilities" tab. If you cannot
see such a tab, you are on a multi-arch image. Drill down into the x86\_64 component image to see the vulnerability
report.
