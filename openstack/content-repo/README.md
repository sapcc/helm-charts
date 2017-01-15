# Content Repo Chart

Mirror http repos directly into swift without the need of physical provided local storage.

## Requirements

A running OpenStack ObjectStore aka Swift to mirror http content in.

## Basic functionality

See https://github.com/sapcc/swift-http-import

## Deactivated features

Currently the default rollout method is via Jobs. If your kubernetes cluster supports ScheduledJobs you can enable that deploy option via:

```
mv templates/_scheduledJob.yaml templates/scheduledJob.yaml
mv templates/job.yaml templates/_job.yaml
```
