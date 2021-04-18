# NOTE The following configuration has to be provided when Consul is NOT running in '-dev' mode.
# For Consul client
ports {
  "grpc" = 8502
}

client_addr = "127.0.0.1"
data_dir = "/tmp/consul/"
