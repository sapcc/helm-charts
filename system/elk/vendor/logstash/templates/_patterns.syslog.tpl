# This is a flexable grok pattern file for syslog. By default, it attempts to be
# relaxed and accomodate implimentation variations.

# valid priority range from 0 to 191, but 00 or 001 technically not legitimate
# according to RFC 3164.
SYSLOGPRINUMSTRICT (?:0|(?:(?:[1-9][0-9])|(?:1[0-8][0-9])|(?:19[0-1])))
# the example below is less precise but hopefully faster. Rather use range 
# checking logic in conf.
SYSLOGPRINUMRELAXED [0-9]{1,3}
SYSLOGPRISTRICT <%{SYSLOGPRINUMSTRICT:priority:int}>
SYSLOGPRIRELAXED <%{SYSLOGPRINUMRELAXED:priority:int}>
SYSLOGPRI %{SYSLOGPRIRELAXED}

# RFC3164
SYSLOG3164TIMESTAMPSTRICT (?:(?:Jan)|(?:Feb)|(?:Mar)|(?:Apr)|(?:May)|(?:Jun)|(?:Jul)|(?:Aug)|(?:Sep)|(?:Oct)|(?:Nov)|(?:Dec)) (?:(?:0[1-9])|(?:[12][0-9])|(?:3[01])|[1-9]) (?:2[0123]|[01][0-9]):(?:[0-5][0-9]):(?:(?:[0-5]?[0-9]|60)(?:[:.,][0-9]+)?)
# Try be even more flexable then RFC3164 and also allow ISO8601 timestamps.
SYSLOG3164TIMESTAMPRELAXED (?:%{MONTH} +%{MONTHDAY} %{TIME})|%{TIMESTAMP_ISO8601}
SYSLOG3164TIMESTAMP %{SYSLOG3164TIMESTAMPRELAXED:timestamp_source}
# Hostname or IP allowed in RFC 3164, but not supposed to be FQDN. Can be 
# flexable and allow it.
HOSTNAMEONLY (?!-)[a-zA-Z0-9-]{1,63}(?<!-)
SYSLOG3164HOSTNAMESTRICT (?:%{HOSTNAMEONLY}|%{IP})
SYSLOG3164HOSTNAMERELAXED %{IPORHOST}
SYSLOG3164HOSTNAME %{SYSLOG3164HOSTNAMERELAXED:host_source}
# For the RFC3164 header, avoid matching RFC 5424 with a negative lookhead for a
# 5424 version number. Also assume that given a timestamp, a hostname aught 
# to follow 
SYSLOG3164HDR ^(?:%{SYSLOGPRI}(?!%{SYSLOG5424VER} ))?(?:%{SYSLOG3164TIMESTAMP} (:?%{SYSLOG3164HOSTNAME} )?)?
# The pattern below is bit stricter than the RFC definiton for tags. Technically 
# the tag is supposed to be only alphanumeric and terminate on first 
# non-alphanum character. However, many programs don't obey that. Generally 
# a colon or left sqaure bracket terminates the tag. In addition, exclude '<'
# character as not appropriate for a program name, given it can cause confusion 
# with a syslog priority header
SYSLOG3164TAG [^:\[<]{1,32}
SYSLOG3164PID \[%{POSINT:pid}\]
SYSLOG3164CONTENT %{GREEDYDATA:message_content}
SYSLOG3164MSG (%{SYSLOG3164TAG:program}(?:%{SYSLOG3164PID})?: ?)?%{SYSLOG3164CONTENT}
SYSLOG3164 %{SYSLOG3164HDR}%{SYSLOG3164MSG:message_syslog}

# RFC5424
SYSLOG5424VER [0-9]{1,2}
# Timestamp is ISO8601 - the version in grok-patterns wasn't as strict as it was defined in the RFC
SYSLOG5424TIMESTAMPSTRICT [0-9]{4}-(?:0[1-9]|1[0-2])-(?:(?:0[1-9])|(?:[12][0-9])|(?:3[01])|[1-9])T(?:[01][0-9]|2[0123]):(?:[0-5][0-9]):(?:[0-5][0-9])(?:[.][0-9]{1,6})?(?:Z|[+-](?:[01][0-9]|2[0123]):[0-5][0-9])
SYSLOG5424TIMESTAMPRELAXED %{TIMESTAMP_ISO8601}
SYSLOG5424TIMESTAMP %{SYSLOG5424TIMESTAMPRELAXED}
# Hostname can be FQDN, DNS label/hostname only or IP
SYSLOGRFC5424HOSTNAME %{IPORHOST}
SYSLOG5424PRINTASCII [!-~]+
SYSLOG5424APPNAME [!-~]{1,48}
SYSLOG5424PROCID [!-~]{1,128}
SYSLOG5424MSGID [!-~]{1,32}
# Practically, only one version for now, and trying to parse future versions 
# would be unwise. So 1 'hardcoded'.
SYSLOG5424HDR ^%{SYSLOGPRI}1 (?:%{SYSLOG5424TIMESTAMP:timestamp_source}|-) (?:%{SYSLOGRFC5424HOSTNAME:host_source}|-) (?:%{SYSLOG5424APPNAME:program}|-) (?:%{SYSLOG5424PROCID:pid}|-) (?:%{SYSLOG5424MSGID:msgid}|-)
# Replace the 1 above with %{SYSLOG5424VER:syslog_version} to cater for 
# additional versions.
SYSLOG5424STRUCTDATA \[%{DATA}\]+
SYSLOG5424MSG %{GREEDYDATA:message_content}
SYSLOG5424 %{SYSLOG5424HDR} (?<message_syslog>(?:%{SYSLOG5424STRUCTDATA:structured_data}|-)( ?%{SYSLOG5424MSG})?)

# Try match and capture RFC 5424 first, given RFC 3164 allows messages without any syslog header. 
# Otherwise, RFC 3164 could accidentally capture an RFC 5424 priority and header as the tag or host of a raw message
SYSLOG %{SYSLOG5424}|%{SYSLOG3164}
