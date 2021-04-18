# NOTE The following configuration has to be provided when Consul is NOT running in '-dev' mode.
# For Consul server
ports {
  "grpc" = 8502
}

# For Consul server
connect {
  enabled = true
}

bind_addr = "127.0.0.1"
data_dir = "/tmp/consul/"
node_name = "consul-devagent"

server = true
bootstrap_expect = 1

ui_config {
  enabled = true
}
