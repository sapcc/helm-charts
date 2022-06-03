# Using Helm-Hooks with Kubectl Pod for Configuration Changes

status: proposed \
date: 2022-06-03 \
deciders: \
consulted: @majewsky \
informed: @galkindmitrii, @notandy, @IvoGoman, @Carthaca, @auhlig, @viktor-kovacs, @databus23

## Context and Problem Statement

In the face of improving our reliability, we need to apply some changes to applications, which are not yet in a HA setup.
The HA setup for each application shall be pursued separately and supersede this proposal.

How to configure running applications which provide an API for that? \
How to avoid downtimes doing so? \
How to current need handle database / user-changes? \
How to minimise effort in face of upcoming transition to HA solutions? \
How do we handle a rollback? \
How do we avoid locking ourselves out?

## Considered Options

* Helm-Chart Hook
    * Job with Same Image
    * Job with Different Image
* Wait for Proper Solution
* Restart Only
    * Checksum-annotations
    * PostStart-Hook
    * Reloader
* Move it to Pipeline
* Monitoring
    * Same Container
    * Same Pod, Different Container / Same Image
    * Same Pod, Different Container / Different Image
    * Different Pod / Same Image
    * Operator (Different Pod / Other Image)

## Decision Outcome

Chosen option: "Helm-chart hook with different image", because it comes out best (see below).

### Positive Consequences

* We gain the ability to apply configuration changes without downtime
* We only need to modify the helm-charts
  * No changes to the pipelines,
  * Upstream images can be used
* Rollback can be easily handled by implementing the corresponding hook.

### Negative Consequences

* The service charts gain the dependency to another image, which needs to be updated.
  However, since it is limited to deployment time, there is no need to trigger a deployment
  on change.

## Pros and Cons of the Options

Almost all options exists as "Same Image" and "Different Image" variant, so first have a look at those.

### Same Image

One can use the same image as the one providing the application and add a layer
which contains the logic of applying the configuration, or use a completely separate image.
It is the only option, when wanting to run the logic in the same container as the application

* Good, because it would be a single dependency
* Good, because the configuration tools are included in the image already
* Neutral, because it would be an application specific solution
* Bad, because we need extra pipelines to add out configuration logic to the images
* Bad, because a change of the configuration logic would/should always trigger a deployment, ie. downtime

### Different Image

The opposite of "Same Image".

### Helm-Chart Hook

We could make use of helm-chart [hooks](https://helm.sh/docs/topics/charts_hooks/) for upgrade and rollback.

* Good, as we make use of the exiting "edge" triggers
* Neutral, as configuration changes outside of helm deployments (manually or otherwise) would not be applied automatically.

### Wait for Proper HA Solution

We plan to move to a proper yet undefined HA setup for all those services affected
The HA setup though requires still some exploration and evaluation, and should be done with care.

* Good, because it is the proper HA solution
* Bad, as in the short to mid term, we cannot apply changes at all or at least without downtime
* Bad, because it puts more pressure on the exploration and selection of the
  HA setup, which requires some time and care

### Restart Only

There are various ways to tie a reconfiguration ot the life-cycle of a pod.
Most commonly, we use checksum annotations in the charts. There exists an operator,
which automates that ([Reloader](https://github.com/stakater/Reloader)).
One can also tie into the life-cycle "postStart"-Hook, but the additional complication here is that until the hook has finished,
the pod won't be marked ready, so the configuration adds to the downtime of the restart.

* Good, because it works and we have experience with that
* Bad, because it causes downtimes

### Move it to Pipeline

We use a CI pipeline to deploy the changes, we can imply extend the pipeline by
some steps.

* Good, because the step(s) would have an explicit representation in the pipeline (failure/success)
* Neutral, as the rollback functionality in helm would could not be used to roll back a release.
* Bad, as it is unclear how we can do that in a generic way, especially since the configuration is in the charts & values.

### Monitoring - Same Container

One can implement a monitoring of configmaps / secrets as a process inside the same
container.

* Good, because one could reuse the capabilities of the application to realise the monitoring (polling)
* Bad, it is against the best practices: One process, one container. There is no resource isolation (CPU/RAM) between
  the monitoring process and the one providing the service.

### Monitoring - Same Pod, Different Container

The monitoring can be moved to a side-car container.

* Good, as the process would be isolated from the main process
* Neutral, avoiding a lockout would require a remote execution kubernetes call so that the application authorise via the user-id.
* Bad, as we need to allocate extra resources for it


### Monitoring - Operator

The monitor could run in a different pod as an operator.

* Good, as the operator would have its own life-cycle.
* Bad, as it would require implementing it
* Bad, as we need to allocate resource (CPU/RAM) for it
