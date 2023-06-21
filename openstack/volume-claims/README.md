# volume-claims

All OpenStack services used to be lumped together in one massive Helm chart
(usually called the "region chart"). Since that turned out very quickly to be a
bad idea, services were split off into their own charts one after the other.
However, the database PVCs stayed in the region chart because the risk of data
loss was too great. When migrating from Helm 2 to Helm 3, we did not have the
original region charts anymore. Therefore, this chart was constructed from
scratch to represent the existing state of the PVCs in question, and they were
manually adopted into this chart.

Deploy like this:

```shellSession
$ u8s helm3 diff upgrade volume-claims . --set global.region="$(u8s env | awk -F= '/U8S_CONTEXT/{print$2}')"
...verify output...
$ u8s helm3 upgrade volume-claims . --set global.region="$(u8s env | awk -F= '/U8S_CONTEXT/{print$2}')"
```
