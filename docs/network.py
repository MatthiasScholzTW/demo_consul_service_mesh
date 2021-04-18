from diagrams import Cluster, Diagram, Edge

from diagrams.generic.compute import Rack
from diagrams.generic.device import Mobile
from diagrams.generic.network import Router
from diagrams.onprem.network import Consul
from diagrams.onprem.monitoring import Prometheus

# Use filename as diagram name and export the diagram next to the file
import os
dir_path = os.path.dirname(os.path.realpath(__file__))
file_name = os.path.splitext(os.path.basename(os.path.realpath(__file__)))[0]
diagram_path = os.path.join(dir_path, file_name)
print(f"INFO :: Exporting diagram to '{diagram_path}.png'")

graph_attr = {
    "fontname": "OpenSans:light",
    "fontsize": "24"
    #"bgcolor": "transparent"
}

with Diagram(name="Consul Service Mesh", filename=diagram_path, graph_attr=graph_attr, direction="LR", show=True):

    #metrics = Prometheus()
    #scrape = Edge(label="scrape", style="dashed")

    with Cluster("Service Mesh"):

        with Cluster("Upstream Service"):
            upstream = Rack("nc")
            sidecar_upstream = Router("sidecar proxy: 9191")

        with Cluster("Downstream Service"):
            downstream = Rack("socat: 8181")
            sidecar_downstream = Router("sidecar proxy: 9191")

        mtls = Edge(label="mtls", color="green")
        plain = Edge(label="unencrypted", color="yellow")

        # Service Mesh Communication
        upstream >> plain >> sidecar_upstream >> mtls >> sidecar_downstream >> plain >> downstream

        # Consul Service Registration
        consul = Consul()
        register = Edge(label="register", style="dashed")
        consul - register - upstream
        consul - register - downstream
        sidecar_upstream >> register >> consul
        sidecar_downstream >> register >> consul

        # Observability
        #metrics >> scrape >> sidecar_upstream
        #metrics >> scrape >> sidecar_downstream
        #metrics >> scrape >> consul
