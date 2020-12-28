from diagrams import Cluster, Diagram, Edge

from diagrams.onprem.network import Consul

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

with Diagram(name="Consul Connect (local)", filename=diagram_path, graph_attr=graph_attr, show=True):
    with Cluster("local"):
        consul = Consul("dev mode")
