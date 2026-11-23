# Image digest regression checks

From the repository root:

```sh
helm dependency build global/andromeda
python3 global/andromeda/ci/test-image-digests.py
```

From this chart directory, run `python3 ci/test-image-digests.py` instead.
Requires Helm, Mike Farah yq v4, Python 3, git, and access to the locked OCI
dependencies. Dependency archives are local test inputs, not committed changes.
The test restores the original templates from commit
`04f4dbf7da48feb93e052fe1e2597f8415cae1e1` in a temporary chart, with identical
chart metadata and real dependencies, and compares full ordinary renders.
It also compares pinned/ordinary output after normalizing the image pin and Job
name, and checks images, Job names, dependencies, labels and digest rotation.
Extreme release/name overrides already overflow unrelated component labels;
only exact original label values are exempted in those extreme cases.
