# coredump-exporter

Ships coredumps written by `systemd-coredump` on the nodes to Swift.

Dumps from `/var/lib/systemd/coredump/` are uploaded every `pollingDelay`
seconds to `swift:<swiftContainer>` under flat object names; the first pass
takes everything, later passes only files newer than
`pollingDelay + pollingFudging`. `X-Delete-After` sets the Swift-side retention,
`X-Object-Meta-*` carries the Garden Linux release and the host name.

## Values

| Value | Default | Description |
| --- | --- | --- |
| `imageName` / `imageVersion` | rclone | rclone image, version is required |
| `osAuthUrl` | – | Keystone v3 URL, set per region |
| `swiftUserDomainName` | `Default` | user domain |
| `swiftProjectName` | `master` | project that owns the container |
| `swiftProjectDomainName` | `ccadmin` | project domain |
| `swiftContainer` | `coredump-exporter` | target container |
| `swiftEndpointType` | `internal` | Keystone catalog endpoint type |
| `username` / `password` | – | secrets-injector references, set per region |
| `pollingDelay` | `300` | seconds between passes |
| `pollingFudging` | `30` | seconds added to the age window of a pass |
| `swiftDeleteAfter` | `864000` | Swift object expiry in seconds |
| `rcloneOperation` | `copyto` | rclone operation, `moveto` would remove local dumps |
| `pod.nodeSelector`, `pod.tolerations` | `{}` | scheduling constraints |

## Troubleshooting

- `403 Forbidden` on upload: the user lacks `objectstore_admin` on the project,
  or the container is missing and cannot be created.
- `NoSuchContainer`: the seed has not run (enable `enable_coredump_exporter` in
  the region's `nova` values).
- Nothing uploaded although dumps exist: check `coredump.enabled` for the node
  pool.
