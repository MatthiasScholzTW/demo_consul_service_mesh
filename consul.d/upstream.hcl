service {
  name = "upstream"
  id = "upstream"
  port = 8181

  connect {
    sidecar_service {}
  }

  # Using netcat to check if the TCP port is usable
  check {
    id = "nc"
    name = "netcat TCP on port 8181"
    tcp = "localhost:8181"
    interval = "2s"
    timeout = "1s"
  }
}
