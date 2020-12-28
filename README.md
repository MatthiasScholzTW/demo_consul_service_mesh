# Demo Consul Connect

Learning Consul Connect and applying it.

## Quickstart

Run the following commands in separate terminals:

1. `make consul`
1. `make service`
1. `make service-sidecar-socat`
1. `make service-sidecar-web`
1. `make test-encryption`

## Connect

### Consul

#### Service

Register sidecar process for the service in [socat.json](./consul.d/socat.json):

```json
{ ... "connect": { "sidecar_service": {} } }
```

This will not start the sidecar, but only informs consul about its existence.
Use:
- `make service-sidecar-socat`
to start the sidecar.

#### Sidecar

Register sidecar process for the sidecar in [web.json](./consul.d/web.json).

This will not start the sidecar, but only informs consul about its existence.
Use:
- `make service-sidecar-web`
to start the sidecar.

### Sidecar

1. Sidecar service: `make service-sidecar-socat`
1. Local service to connect to sidecar: `make service-sidecar-web`
1. Test connection `make test-encryption`


## Intentions

Defines which service may communicate. 
In the development mode by default all is allowed.

NOTE 2020-12-28: Changing intentions will _not_ affect existing connections!
-> Will be addressed in a future version of consul.

## Remarks

### Development Mode

ACL system ( and hence Intentions ) are by default _Allow All_.

### Local Traffic

Connection between proxies is encrypted and authorized.
Local connection to and from the proxy are _unencrypted_ - this represents the loopback connection.
Traffic in and out of the machine is always encrypted.

### Socat

Only supports tcp. No support for tls.


## References

- https://learn.hashicorp.com/tutorials/consul/get-started-service-networking
- TODO: Link Consul Connect Production Guide


## Questions

### TODO Why are there two sidecars: sidecar-socat and sidecar-web?

Or what is the purpose of `make service-sidecar-socat`?
