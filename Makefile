service_name := socat
service_port := 8181
service_user_name := web
service_user_port := 9191

setup:
	@echo "INFO :: Installing consul and socat locally!"
	brew install hashicorp/tap/consul
	brew install socat

cleanup:
	@echo "INFO :: Removing consul and socat from the local machine."
	brew uninstall consul
	brew uninstall socat
	rm -rf ./logs

logs:
	mkdir -p ./logs


consul: logs
	consul agent -dev -config-dir=./consul.d -node=machine > ./logs/consul.log 2>&1 &

service: logs
	socat -v tcp-l:$(service_port),fork exec:"/bin/cat"  > ./logs/service_$(service_name).log 2>&1 &

service-sidecar-socat: logs
	consul connect proxy -sidecar-for $(service_name)  > ./logs/sidecar_$(service_name).log 2>&1 &

service-sidecar-web: logs
	consul connect proxy -sidecar-for $(service_user_name)  > ./logs/sidecar_$(service_user_name).log 2>&1 &


start: consul service service-sidecar-socat service-sidecar-web
	@echo "INFO :: Consul Service Mesh started. Use 'make test-service-mesh' to check the setup."

stop:
	@echo "INFO :: Terminating all Consul and socat processes."
	killall consul
	killall socat


intention-deny:
	@echo "INFO :: Creation of an intetion to deny traffic."
	consul intention create -deny $(service_user_name) $(service_name)

intention-delete:
	@echo "INFO :: Deletion of the intention to allow traffic."
	consul intention delete $(service_user_name) $(service_name)

test-service:
	@echo "INFO :: Usage: Text send should be echoed back."
	nc 127.0.0.1 $(service_port)

test-service-mesh:
	nc 127.0.0.1 $(service_user_port)

doc:
	@echo "INFO :: Installing diagram creation dependencies locally!"
	brew install graphviz
	python3 -m pip install diagrams
	@echo "INFO :: Creating the diagram."
	@python3 docs/network.py
