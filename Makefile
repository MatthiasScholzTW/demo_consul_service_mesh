service_name := socat
service_port := 8181
service_user_name := web
service_user_port := 9191

setup:
	@echo "INFO :: Installing Consul and socat locally!"
	brew install hashicorp/tap/consul
	consul -version
	brew install socat
	@echo "INFO :: Installing Envoy locally!"
	brew tap tetratelabs/getenvoy
	brew install envoy
	envoy --version

cleanup:
	@echo "INFO :: Removing consul and socat from the local machine."
	brew uninstall consul
	brew uninstall socat
	rm -rf ./logs

logs:
	mkdir -p ./logs


# NOTE: Consul Connect is enabled by default when using "-dev" mode.
consul: logs
	consul agent -dev -config-dir=./consul.d -node=machine > ./logs/$@.log 2>&1 &
	@echo "INFO :: Giving Consul some time to start up."
	sleep 2

service: logs
	socat -v tcp-l:$(service_port),fork exec:"/bin/cat" > ./logs/$@_$(service_name).log 2>&1 &

service-sidecar-socat: logs
	consul connect proxy -sidecar-for $(service_name)  > ./logs/$@.log 2>&1 &

service-sidecar-socat-envoy: logs
	consul connect envo y -sidecar-for $(service_name) -admin-bind localhost:19001

service-sidecar-web: logs
	consul connect proxy -sidecar-for $(service_user_name)  > ./logs/$@.log 2>&1 &

service-sidecar-web-envoy: logs
	consul connect envoy -sidecar-for $(service_user_name)

start: consul service service-sidecar-socat service-sidecar-web intention-allow
	@echo "INFO :: Consul Service Mesh started. Use 'make test-service-mesh' to check the setup."

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
	ps -a | grep $(service_name)
	ps -a | grep $(service_user_name)

register-services:
	@echo "INFO :: Register the services"
	consul services register ./consul.d/socat.hcl
	consul services register ./consul.d/web.hcl
	@echo "INFO :: Verify service registration"
	consul catalog services | ag $(service_name)
	consul catalog services | ag $(service_user_name)

intention-allow:
	@echo "INFO :: Creation of an intetion to allow traffic."
	consul intention create $(service_user_name) $(service_name)

intention-deny:
	@echo "INFO :: Creation of an intetion to deny traffic."
	consul intention create -deny $(service_user_name) $(service_name)

intention-delete:
	@echo "INFO :: Deletion of the intention to allow traffic."
	consul intention delete $(service_user_name) $(service_name)

service_log := "./logs/service_socat.log"
test_string := "SomeTestString"

test-service:
	@echo "INFO :: Usage: Text send should be echoed back."
	@echo "INFO :: .Testing connection"
	@nc -z 127.0.0.1 $(service_port)
	@echo "INFO :: .Testing sending some data: '$(test_string)'"
	@echo $(test_string) | nc 127.0.0.1 $(service_port)
	@grep $(test_string) $(service_log) > /dev/null || ( echo "ERROR :: test data not transmitted" && exit 1 )
	@echo "INFO :: Test succeeded."

test-service-mesh:
	@echo "INFO :: Starting netcat to communicate using the Consul Service Mesh"
	@echo "INFO :: .Testing connection"
	@nc -z 127.0.0.1 $(service_user_port)
	@echo "INFO :: .Testing sending some data: '$(test_string)'"
	@echo $(test_string) | nc 127.0.0.1 $(service_user_port)
	@grep $(test_string) $(service_log) > /dev/null || ( echo "ERROR :: test data not transmitted" && exit 1 )
	@echo "INFO :: Test succeeded."

doc:
	@echo "INFO :: Installing diagram creation dependencies locally!"
	brew install graphviz
	python3 -m pip install diagrams
	@echo "INFO :: Creating the diagram."
	@python3 docs/network.py
