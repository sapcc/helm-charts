#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# Since the tugger chart is not published into any Helm package repos, we need
# to vendor it ourselves. We go through a vendor/ directory instead of just
# putting a tarball into charts/ because we want to use condition flags, which
# only work in the `dependencies` section of Chart.yaml.

if [ ! -d repo/tugger ]; then
  git clone --bare https://github.com/jainishshah17/tugger repo/tugger
fi
git -C repo/tugger remote update

rm -rf ./tugger
git -C repo/tugger archive origin/master chart/tugger/ | tar x ### NOTE: replace "origin/master" with a tag like "v0.4.3" to vendor a tagged version
mv ./chart/tugger ./tugger
rmdir ./chart
