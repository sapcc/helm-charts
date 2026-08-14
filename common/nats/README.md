# NATS

## Changelog

### 0.20.0

* Added `appProtocol=linkerd.io/opaque` to all `.spec.ports` entries in order to skip protocol detection (see rationale below)

From the [official documentation](https://linkerd.io/2-edge/features/protocol-detection/#declaring-a-service-ports-protocol):

> Declaring a Service port’s protocol
> When you’re getting started with Linkerd, automatic protocol detection works in the majority of cases, but it runs the risk that if a connection ever takes more than 10 seconds to send enough data, it might not detect the protocol. This could happen in situations where the cluster is overloaded, the proxy is resource constrained, the app is resource constrained, etc.
> To eliminate this risk, you can set the appProtocol field on the ports in a Service to determine what protocol to use when communicating with that Service port, and skip automatic protocol detection entirely.

### 0.19.0

* Added required `service.externalTrafficPolicy` for supporting migration to Calico
