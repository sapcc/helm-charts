# Image digest regression checks

From the repository root:

```sh
helm dependency build openstack/cinder
python3 openstack/cinder/ci/test-image-digests.py
```

From this chart directory, run `python3 ci/test-image-digests.py` instead.
Requires Helm, Mike Farah yq v4, Python 3, git, and access to the locked OCI
dependencies. Dependency archives are local test inputs, not committed changes.
The test restores the original helper from commit
`04f4dbf7da48feb93e052fe1e2597f8415cae1e1` in a temporary chart, with identical
chart metadata and real dependencies, and compares full ordinary renders.
It also compares pinned/ordinary output after normalizing the image pin and Job
names, checks both Jobs and all dependency references (including embedded
VCenterTemplate consumers), and covers ProxySQL off/host_alias/unix_socket,
long releases/tags and the API-specific image override.
