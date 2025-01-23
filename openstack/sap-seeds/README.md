These seeds should take care of any additional configuration.

It is likely highly specific to SAP.

Any seed, which is essential for a service to run needs to be placed into the respective service requiring it.


### Removed flavors

Removed flavors are kept _private_ ("is_public: false") in here instead of
actually deleting them to allow management of old instances with these
flavors.

To query if one or more flavors are still in use run the following query in
the "nova" DB (replace `$FLAVOR` with the flavor name(s)) of every region:

```sql
SELECT
    i2.project_id,
    i2.created_at,
    i2.uuid,
    i2.host,
    i2.hostname AS name,
    j1.flavor
  FROM instances AS i2
  JOIN (
       SELECT
           instance_uuid,
           json_value(flavor, '$.cur."nova_object.data".name') AS flavor
       FROM instance_extra AS ie
       JOIN (SELECT uuid FROM instances WHERE deleted = 0) AS i
       ON i.uuid = ie.instance_uuid
   ) AS j1
   ON j1.instance_uuid = i2.uuid
   WHERE flavor in ('$FLAVOR');
```
