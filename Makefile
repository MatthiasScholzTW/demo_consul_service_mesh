service_name_upstream := upstream
service_port_unencrypted := 8181
service_name_downstream := downstream
service_port_encrypted := 9191

start: consul-dev upstream upstream-sidecar downstream downstream-sidecar intention-allow
	@echo "INFO :: Consul Service Mesh started."
	@echo "INFO :: Use 'make test-service-mesh' to check the setup."

test-service:
	@echo "INFO :: Usage: Text send should be echoed back."
	@echo "INFO :: .Testing connection"
	@nc -z 127.0.0.1 $(service_port_unencrypted)
	@echo "INFO :: .Testing sending some data: '$(test_string)'"
	@echo $(test_string) | nc 127.0.0.1 $(service_port_unencrypted)
	@grep $(test_string) $(upstream_log) > /dev/null || ( echo "ERROR :: test data not transmitted" && exit 1 )
	@echo "INFO :: Test succeeded."

test-service-mesh:
	@echo "INFO :: Starting netcat to communicate using the Consul Service Mesh"
	@echo "INFO :: .Testing connection"
	nc -z 127.0.0.1 $(service_port_encrypted)
	@echo "INFO :: .Testing sending some data: '$(test_string)'"
	echo $(test_string) | nc 127.0.0.1 $(service_port_encrypted)
	grep $(test_string) $(service_log) > /dev/null || ( echo "ERROR :: test data not transmitted" && exit 1 )
	@echo "INFO :: Test succeeded."


envoy_version_1-16-2 := https://github.com/Homebrew/homebrew-core/commit/f1a8723cb5470454b306ac6531fe7b63efa2dba8
prerequistes-%:
	@echo "INFO :: Installing Consul and socat locally!"
	brew $* hashicorp/tap/consul
	consul -version
	brew $* socat
	@echo "INFO :: Installing Envoy locally!"
	brew tap tetratelabs/getenvoy
  # NOTE: Only consul 1.10 will provide support for envoy 1.17
	# brew $* envoy
	brew extract --version=1.16.1 $(envoy_version_1-16-2) tetratelabs/getenvoy
	envoy --version

install: prerequistes-install
upgrade: prerequistes-upgrade

logs:
	mkdir -p ./logs

validate:
	consul validate ./consul.d

consul: logs validate
	consul agent -config-dir=./consul.d -node=machine > ./logs/$@.log 2>&1 &
	@echo "INFO :: Giving Consul some time to start up."
	sleep 4
	open http://localhost:8500

# NOTE: Consul Connect is enabled by default when using "-dev" mode.
consul-dev: logs
	consul agent -dev -config-dir=./consul.d -node=machine > ./logs/$@.log 2>&1 &
	@echo "INFO :: Giving Consul some time to start up."
	sleep 4
	open http://localhost:8500

consul-ui:
	open http://localhost:8500

restart: stop consul

upstream: logs
	socat -v tcp-l:$(service_port_unencrypted),fork exec:"/bin/cat" > ./logs/$@_$(service_name_upstream).log 2>&1 &

upstream-foreground:
	socat -v tcp-l:$(service_port_unencrypted),fork exec:"/bin/cat"


upstream-sidecar: logs
	consul connect proxy -sidecar-for $(service_name_upstream)  > ./logs/$@.log 2>&1 &

upstream-sidecar-foreground:
	consul connect proxy -sidecar-for $(service_name_upstream)

upstream-sidecar-envoy: logs
	consul connect envoy -sidecar-for $(service_name_upstream) -admin-bind localhost:19001

downstream: logs
	@echo "INFO :: No downstream service needs to be lanched for the local setup to demonstrate the service mesh encrypted connection. The port $(service_user_port) can be used directly."

downstream-sidecar: logs
	consul connect proxy -sidecar-for $(service_name_downstream) > ./logs/$@.log 2>&1 &

downstream-sidecar-forground:
	consul connect proxy -sidecar-for $(service_name_downstream)


downstream-sidecar-envoy: logs
	consul connect envoy -sidecar-for $(service_name_downstream)

stop:
	@echo "INFO :: Terminating all Consul and socat processes."
	killall consul
	killall socat
	killall envoy

reload:
	consul reload

status:
	@echo "INFO :: Listing the processes"
	ps -a | grep consul
	ps -a | grep envoy
	ps -a | grep $(service_name_upstream)
	ps -a | grep $(service_name_downstream)

consul_config := ./consul.d/consul_server.hcl
status-connect:
	@echo "INFO :: Testing if Consul Service Mesh is up"
	@awk '/connect/,/}/' $(consul_config) | grep true || ( echo "ERROR :: Consul Connect NOT enabled" && exit 1 )

register-services:
	@echo "INFO :: Register the services"
	consul services register ./services/upstream.hcl
	consul services register ./services/downstream.hcl
	@echo "INFO :: Verify service registration"
	consul catalog services | ag $(service_name_upstream)
	consul catalog services | ag $(service_name_downstream)

intention-allow:
	@echo "INFO :: Creation of an intetion to allow traffic."
	consul intention create $(service_name_downstream) $(service_name_upstream)

intention-deny:
	@echo "INFO :: Creation of an intetion to deny traffic."
	consul intention create -deny $(service_name_downstream) $(service_name_upstream)

intention-delete:
	@echo "INFO :: Deletion of the intention to allow traffic."
	consul intention delete $(service_name_downstream) $(service_name_upstream)

upstream_log := "./logs/service_upstream.log"
test_string := "SomeTestString"

cleanup: cleanup-logs
	@echo "INFO :: Removing consul and socat from the local machine."
	brew uninstall consul
	brew uninstall socat

cleanup-logs:
	rm -rf ./logs


doc:
	@echo "INFO :: Installing diagram creation dependencies locally!"
	brew install graphviz
	python3 -m pip install diagrams
	@echo "INFO :: Creating the diagram."
	@python3 docs/network.py
