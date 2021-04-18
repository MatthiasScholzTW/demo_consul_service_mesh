service {
  name = "downstream"
  # NOTE: Port is irrelevant, because it is running on a local machine and
  #       the user itself is the upstream service.
  #       -> Using the encrypted connection directly.
  port = 6666

  connect {
    sidecar_service {
      proxy {
        upstreams = [
          {
            destination_name = "upstream"
            local_bind_port  = 9191
          }
        ]
      }
    }
  }
}
