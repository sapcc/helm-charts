This checks finds containers whose images depend on very old base images, by checking the build timestamp of each layer.

#### Why is this a problem?

Outdated base images may contain software with known or unknown vulnerabilities, not just for the libraries and
applications you rely on, but also for OS-level components and shell utilities. Also, it's generally a good idea to
rebuild all your images at least somewhat regularly to preserve the institutional knowledge on how to build and deploy
updated images.

#### How to fix?

Rebuild your images using a newer base. It may not even be necessary to upgrade: Some base image providers will rebuild
their tagged images from time to time to incorporate bugfix releases and OS package updates. Keppel will automatically
replicate this kind of update into our mirror accounts.
