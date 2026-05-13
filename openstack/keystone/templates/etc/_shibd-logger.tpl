# set overall behavior
log4j.rootCategory=INFO, shibd_log, warn_log

# fairly verbose for DEBUG, so generally leave at INFO
log4j.category.XMLTooling.XMLObject=INFO
log4j.category.XMLTooling.XMLObjectBuilder=INFO
log4j.category.XMLTooling.KeyInfoResolver=INFO
log4j.category.Shibboleth.IPRange=INFO
log4j.category.Shibboleth.PropertySet=INFO

# raise for low-level tracing of SOAP client HTTP/SSL behavior
log4j.category.XMLTooling.libcurl=INFO

# logs XML being signed or verified if set to DEBUG
log4j.category.XMLTooling.Signature.Debugger=INFO, sig_log
log4j.additivity.XMLTooling.Signature.Debugger=false
log4j.ownAppenders.XMLTooling.Signature.Debugger=true

# the tran log blocks the "default" appender(s) at runtime
# Level should be left at INFO for this category
log4j.category.Shibboleth-TRANSACTION=INFO, tran_log
log4j.additivity.Shibboleth-TRANSACTION=false
log4j.ownAppenders.Shibboleth-TRANSACTION=true

# define the appenders

# [FIX L-01] maxFileSize increased from 1 MB (package default) to 10 MB.
#   In a multi-tenant deployment, 1 MB log files rotate too quickly,
#   risking loss of audit data before it can be forwarded to central logging.
log4j.appender.shibd_log=org.apache.log4j.RollingFileAppender
log4j.appender.shibd_log.fileName=/var/log/shibboleth/shibd.log
log4j.appender.shibd_log.maxFileSize=10485760
log4j.appender.shibd_log.maxBackupIndex=10
log4j.appender.shibd_log.layout=org.apache.log4j.PatternLayout
log4j.appender.shibd_log.layout.ConversionPattern=%d{%Y-%m-%d %H:%M:%S} %p %c %x: %m%n

# [FIX L-01] WARN+ messages forwarded to container stdout via /proc/1/fd/1
#   (PID 1 = Apache after exec). This enables the central log pipeline to
#   pick up SAML assertion validation failures without a sidecar container.
#   Satisfies BSI SF.FAS.6 (failed assertion checks logged as security events).
log4j.appender.warn_log=org.apache.log4j.FileAppender
log4j.appender.warn_log.fileName=/proc/1/fd/1
log4j.appender.warn_log.layout=org.apache.log4j.PatternLayout
log4j.appender.warn_log.layout.ConversionPattern=%d{%Y-%m-%d %H:%M:%S} %p %c %x: %m%n
log4j.appender.warn_log.threshold=WARN

# [FIX L-01] maxFileSize increased from 1 MB to 10 MB.
#   Transaction log is the SAML audit trail -- must not rotate prematurely.
log4j.appender.tran_log=org.apache.log4j.RollingFileAppender
log4j.appender.tran_log.fileName=/var/log/shibboleth/transaction.log
log4j.appender.tran_log.maxFileSize=10485760
log4j.appender.tran_log.maxBackupIndex=20
log4j.appender.tran_log.layout=org.apache.log4j.PatternLayout
log4j.appender.tran_log.layout.ConversionPattern=%d{%Y-%m-%d %H:%M:%S}|%c|%m%n

log4j.appender.sig_log=org.apache.log4j.FileAppender
log4j.appender.sig_log.fileName=/var/log/shibboleth/signature.log
log4j.appender.sig_log.layout=org.apache.log4j.PatternLayout
log4j.appender.sig_log.layout.ConversionPattern=%m
