MONTH (?:[Jj]an(?:uary|uar)?|[Ff]eb(?:ruary|ruar)?|[Mm](?:a)?r(?:ch|z)?|[Aa]pr(?:il)?|[Mm]a(?:y|i)?|[Jj]un(?:e|i)?|[Jj]ul(?:y)?|[Aa]ug(?:ust)?|[Ss]ep(?:tember)?|[Oo](?:c|k)?t(?:ober)?|[Nn]ov(?:ember)?|[Dd]e(?:c|z)(?:ember)?)
REQUESTID [0-9A-Za-z-]+
SWIFTREQPATH /info|((?:/v1/AUTH_)(?<account>(p-)?[0-9A-Fa-f]+))?(?:/)?(?<container>[0-9A-Za-z$.+!*'(){},~:;=@#_\-]+)?(?:/)?(?<object>[0-9A-Za-z$.+!*'(){},~:;=@#_/\-]+)?
SWIFTREQPARAM (\?|%[0-9A-Fa-f]{2})[A-Za-z0-9$.+!*'|(){},~@#%&/=:;_?\-\[\]]*
SNMP_ERROR [a-zA-Z0-9 ]+
METHOD (GET|POST|PUT)
LOWER [a-z0-9 ]*
IMAGE_METHOD \/v2\/images
URIPROTO [A-Za-z]([A-Za-z0-9+\-.]+)+
URIHOST %{IPORHOST}(?::%{POSINT})?
# uripath comes loosely from RFC1738, but mostly from what Firefox doesn't turn into %XX
URIPATH (?:/[A-Za-z0-9$.+!*'(){},~:;=@#%&_\-]*)+
URIQUERY [A-Za-z0-9$.+!*'|(){},~@#%&/=:;_?\-\[\]<>]*
# deprecated (kept due compatibility):
URIPARAM \?%{URIQUERY}
URIPATHPARAM %{URIPATH}(?:\?%{URIQUERY})?
URI %{URIPROTO}://(?:%{USER}(?::[^@]*)?@)?(?:%{URIHOST})?(?:%{URIPATH}(?:\?%{URIQUERY})?)?
