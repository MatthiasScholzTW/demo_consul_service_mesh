service {
  name = "socat"
  id = "socat"
  port = 8181

  connect {
    sidecar_service {}
  }
}
