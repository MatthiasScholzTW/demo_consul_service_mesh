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

    metrics = Prometheus()
    scrape = Edge(label="scrape", style="dashed")

    with Cluster("Service Mesh"):

        with Cluster("Downstream Service"):
            user = Rack("nc")
            sidecar_user = Router("sidecar proxy")

        with Cluster("Upstream Service"):
            sidecar_service = Router("sidecar proxy")
            service = Rack("socat")

        mtls = Edge(label="mtls", color="green")
        plain = Edge(label="unencrypted", color="yellow")

        # Service Mesh Communication
        user >> plain >> sidecar_user >> mtls >> sidecar_service >> plain >> service

        # Consul Service Registration
        consul = Consul()
        register = Edge(label="register", style="dashed")
        consul - register - service
        sidecar_user >> register >> consul
        sidecar_service >> register >> consul

        # Observability
        metrics >> scrape >> sidecar_user
        metrics >> scrape >> sidecar_service
        #metrics >> scrape >> consul
