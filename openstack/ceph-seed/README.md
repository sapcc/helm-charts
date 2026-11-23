# Ceph service account password rotation

This chart can seed two Keystone accounts for RGW: `ceph@Default` and
`ceph2@Default`. Both have the `service` role on the `admin` project in
the `Default` domain. The second account is optional and disabled by default.
The `ceph-barbican` and `db_backup` accounts have separate rotation procedures.

## Configuration

Enable the second account in the values for `openstack/ceph-seed`:

```yaml
service_user_rotation:
  enabled: true
```

Supply independent Vault references in the regional secret values using the
existing `*vault(path: ..., field: password)` convention:

```yaml
global:
  ceph_service_password: *vault(path: <region>/ceph/keystone-user/service/password, field: password)
  ceph_rotation_service_password: *vault(path: <region>/ceph/keystone-user/ceph2/password, field: password)
```

Replace `<region>` and the rotation secret path with the actual Vault locations.
These are inputs to the deployment pipeline's `vault-injector interpolate` step,
which resolves references before running Helm. Keep the reference in secret
values when rotating; update the password stored in Vault. Plain Helm commands
use the resolved values or the synthetic CI values, rather than raw `*vault` input.

The original account retains its existing single-quoted
`global.ceph_service_password` template. The rotation account uses the same
single-quoted style and escapes apostrophes in the resolved password.
Rendering fails if rotation is enabled without
a nonempty, single-line rotation password, or if that password has leading/trailing whitespace.
The seeder trims string values, so generate both passwords without surrounding
whitespace. Keep actual passwords out of committed values.

Enabling the account does not switch RGW. The active account is selected in
`system/cc-ceph` through `objectstore.keystone.admin_user` and `admin_password`,
which populate the `ceph-keystone-secret` Kubernetes Secret. The primary and
extra object stores reference this same Secret.

## Rotation plan and procedure

Keep both accounts seeded after adopting this mechanism. Alternate between
them on successive rotations. A rotation has three separate deployment phases:
prepare the inactive account, switch consumers, then retire the old password.
Do not update the active account's password during preparation.

1. **Prepare the inactive account.** For the first rotation, generate a fresh
   password for `ceph2`, store it as
   `global.ceph_rotation_service_password`, and enable `service_user_rotation`.
   Deploy `ceph-seed` while RGW still uses `ceph`. Wait for successful seeder
   reconciliation; Helm upgrade success alone does not prove the Keystone
   account exists. If `ceph2` already exists, explicitly update its password in
   Keystone as described below. For later rotations, store a fresh password in
   the inactive account's corresponding global value, deploy the seed to keep
   its definition consistent, and explicitly set that password in Keystone.
   A password-only seed change does not update an existing user's password.
2. **Verify the new account.** Obtain a fresh Keystone token using the inactive
   account, user domain `Default`, project `admin`, and project domain `Default`.
   Confirm the `service` role and the required token-validation/S3-token access.
   Use the normal secret injection workflow for authentication checks.
3. **Switch RGW in a separate deployment.** Set the following `cc-ceph` values
   together, supplying the exact password used in the seed through secret
   values:

   ```yaml
   objectstore:
     keystone:
       admin_user: ceph2
       admin_domain: Default
       admin_project: admin
       admin_password: *vault(path: <region>/ceph/keystone-user/ceph2/password, field: password)
   ```

   Deploy `cc-ceph`. Rook 1.19.10, pinned by this repository, watches the referenced
   Keystone Secret and writes updated credentials to each RGW's Ceph monitor
   configuration. Confirm the deployed version matches and verify propagation
   into every RGW instance. If a restart is required, roll RGW deployments
   with enough healthy instances to maintain service and wait for each rollout
   to finish. A Secret update alone is not evidence that gateways reloaded it.
   Include extra object stores and any other consumers of the old account.
4. **Validate and observe.** Test fresh S3 requests with Keystone-backed EC2
   credentials and fresh Swift authentication/requests. Check RGW and Keystone
   authentication errors and gateway readiness. Allow for service token renewal
   and configured token caches; successful cached requests alone do not prove
   the new credentials work. Retain the old credentials for a bounded rollback
   window.
5. **Retire the old password.** After every consumer has switched and the
   rollback window has closed, replace the old account's password with a fresh,
   unused value in its global seed value, deploy `ceph-seed`, and explicitly
   update the old account's password in Keystone. Verify that the previous
   password cannot obtain a new token. Account for Keystone token
   invalidation and RGW cache/revocation behavior when verifying retirement.
   Keep the unused password in secret storage; the standby account still has
   permission to authenticate.
6. **Reverse the accounts next time.** Refresh `global.ceph_service_password`
   while RGW uses `ceph2`, reconcile the seed, explicitly update `ceph` in
   Keystone and verify its new password, then switch
   `admin_user` back to `ceph` together with its new `admin_password`. Retire the
   previous `ceph2` password only after that rollout succeeds.

## Updating an existing Keystone password

The production seeder's `seed_users` implementation ignores passwords when
comparing an existing user. A metadata change may cause it to resend the password
along with other attributes, but a password-only change is ignored. Always keep
the stored seed password consistent with the intended Keystone password, and
perform the password update explicitly for existing accounts.

Using an authorized administrative OpenStack CLI session:

```sh
openstack user list --domain Default --name ceph2
# Use the exact user ID from the result to avoid same-name users in other domains.
openstack user set --password-prompt <user-id>
```

Enter the fresh password from secret storage when prompted. Use the same
procedure for `ceph` when it is the inactive or retiring account. Verify the new
password obtains a fresh `Default/admin` token and the previous password fails.
Avoid relying on a cached token, `OS_TOKEN`, or application credentials for this
check. Do not delete/recreate either account as part of normal rotation.

The relevant upstream implementations are
[seeder user creation and updates](https://github.com/sapcc/kubernetes-operators/blob/4ff35f494101c3b06c24bb7ea5da2a5cace77d22/openstack-seeder/python/openstack_seeder.py#L414),
[Rook Secret reconciliation](https://github.com/rook/rook/blob/v1.19.10/pkg/operator/ceph/object/controller.go#L221),
and [Rook credential mapping](https://github.com/rook/rook/blob/v1.19.10/pkg/operator/ceph/object/config.go#L128).
Verify the deployed seeder image implements the same behavior before the rollout.

## Rollback and account lifecycle

Before retiring the old password, restore the previous RGW username and password
together, deploy `cc-ceph`, and verify propagation and authentication again.
After retirement, explicitly set and verify a fresh password for the standby account
before switching back; the old password is no longer a rollback credential.

Keep `service_user_rotation.enabled: true` throughout normal rotations. Setting
it to `false` only omits the account from the seed; it does not guarantee deletion
or disabling in Keystone. If you choose to disable or remove a standby account
instead of retiring its password, coordinate that state with the seeder and
verify its reconciliation behavior before depending on it.

## Validation

With chart dependencies available:

```sh
helm lint openstack/ceph-seed -f openstack/ceph-seed/ci/test-values.yaml
helm lint openstack/ceph-seed -f openstack/ceph-seed/ci/rotation-test-values.yaml
helm unittest openstack/ceph-seed
```

The unit tests cover default behavior, independent passwords, the rotation
account's role assignment, missing/empty/whitespace passwords, Vault resolver
expressions, and apostrophes in the rotation password.
These checks validate rendering; live Keystone password updates, permissions,
RGW propagation, and S3/Swift requests must pass before retiring old credentials.
