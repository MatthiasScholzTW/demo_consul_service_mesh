service_name := socat
service_port := 8181
service_sidecar_name := web
service_sidecar_port := 9191

setup:
	@echo "INFO :: Installing consul and socat locally!"
	brew install hashicorp/tap/consul
	brew install socat

cleanup:
	@echo "INFO :: Removing consul and socat from the local machine."
	brew uninstall consul
	brew uinstall socat

consul:
	consul agent -dev -config-dir=./consul.d -node=machine

consul-reload:
	consul reload

service:
	socat -v tcp-l:$(service_port),fork exec:"/bin/cat"

service-sidecar-socat:
	consul connect proxy -sidecar-for $(service_name)

service-sidecar-web:
	consul connect proxy -sidecar-for $(service_sidecar_name)

service-connect-local-dev:
	@echo "INFO :: Start local 'web' service representation for service $(service_name) and provide a MTLS connection on port $(service_sidecar_port) using Consul service discovery."
	@echo "INFO :: This functionality is covered by the consul service configuration in ./consul.d/web.json."
	consul connect proxy -service $(service_sidecar_name) -upstream $(service_name):$(service_sidecar_port)

intention-deny:
	@echo "INFO :: Creation of an intetion to deny traffic."
	consul intention create -deny $(service_sidecar_name) $(service_name)

intention-delete:
	@echo "INFO :: Deletion of the intention to allow traffic."
	consul intention delete $(service_sidecar_name) $(service_name)

test:
	@echo "INFO :: Usage: Text send should be echoed back."
	nc 127.0.0.1 $(service_port)

test-encryption:
	nc 127.0.0.1 $(service_sidecar_port)

doc:
	@echo "INFO :: Installing diagram creation dependencies locally!"
	brew install graphviz
	python3 -m pip install diagrams
	@echo "INFO :: Creating the diagram."
	@python3 docs/network.py
