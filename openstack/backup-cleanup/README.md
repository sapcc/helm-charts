# Backup Cleanup Chart

Simple cleanup deployment for expired backup segments.

The periodic triggered script, will cleanup backup segments of static large
objects in Swift, because the segments are not marked for expirations. The
object expirer only remover the manifest files of the SLOs.
