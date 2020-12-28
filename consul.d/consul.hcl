# NOTE The following configuration has to be provided when Consul is NOT running in '-dev' mode.
# For Consul server and client
ports {
  "grpc" = 8502
}

# For Consul server
connect {
  enabled = true
}
