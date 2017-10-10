# Content Repo Chart

Mirror http repos directly into swift without the need of physical provided local storage.

## Requirements

A running OpenStack ObjectStore aka Swift to mirror http content in.

## Basic functionality

See https://github.com/sapcc/swift-http-import

## Deactivated features

If your kubernetes cluster supports CronJobs you can enable that via specifying a schedule:

```yaml
repos:
  ubuntu:
    schedule: "* */4 * * *"
```
