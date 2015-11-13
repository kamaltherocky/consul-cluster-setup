#! /bin/bash

function create_consul_cluster() {
  # Consul Server Cluster using docker macine
  create_and_configure_host "consul-server-01"
  create_and_configure_host "consul-server-02"
  create_and_configure_host "consul-server-03"
}

function create_consul_agents() {
  # Consul Agents using docker macine
  create_and_configure_host "consul-agent-01"
  create_and_configure_host "consul-agent-02"
}

function create_and_configure_host() {
  # create a node using docker-machine
  docker-machine create --driver virtualbox $1
  # Start the node if it is not Running
  docker-machine start $1
  # Install Python in Boot2Docker VM
  docker-machine ssh $1 "tce-load -w -i python.tcz"
  # Install pip and docker-py in boot2docker VM
  docker-machine ssh $1 "rm -rf get-pip.py && wget https://bootstrap.pypa.io/get-pip.py && sudo python get-pip.py && sudo pip install docker-py"
}

function cleanup_docker_containers() {
  # Kill and remove containers on the node
  docker kill $(docker ps -q)
  docker rm $(docker ps -aq)
}

function print_consul_webui_endpoint() {
  echo "Consul Cluster Web UI URL :"
  echo "---------------------------"
  echo "http://$(docker-machine ip consul-server-01):8500/ui"
  echo "http://$(docker-machine ip consul-server-02):8500/ui"
  echo "http://$(docker-machine ip consul-server-03):8500/ui"
}

# docker-machine kill $(docker-machine ls --filter name="consul*" -q)

create_consul_cluster
create_consul_agents
# Start Consul Docker containers on the created nodes
# Bootstrap Consul Server
eval $(docker-machine env consul-server-01)
cleanup_docker_containers
docker run -d --net host --name=consul-server-01 gliderlabs/consul-server -advertise $(docker-machine ip consul-server-01) -bootstrap-expect=3

eval $(docker-machine env consul-server-02)
cleanup_docker_containers
docker run -d --net host --name=consul-server-02 gliderlabs/consul-server -advertise $(docker-machine ip consul-server-02) -join $(docker-machine ip consul-server-01)

eval $(docker-machine env consul-server-03)
cleanup_docker_containers
docker run -d --net host --name=consul-server-03 gliderlabs/consul-server -advertise $(docker-machine ip consul-server-03) -join $(docker-machine ip consul-server-01)

# Stop the Bootstrap and Join the cluster as Normal Server
# Commented out the rejoining of server without bootstrap. Without bootstrap the recovery of the cluster after outage is not possible
#eval $(docker-machine env consul-server-01)
#cleanup_docker_containers
#docker run -d --net host gliderlabs/consul-server -advertise $(docker-machine ip consul-server-01)  -join $(docker-machine ip consul-server-02)

# Start Consul Agent and Join the Consul Cluster
eval $(docker-machine env consul-agent-01)
cleanup_docker_containers
docker run -d --net host --name=consul-agent-01 gliderlabs/consul-agent -advertise $(docker-machine ip consul-agent-01) -join $(docker-machine ip consul-server-01)

eval $(docker-machine env consul-agent-02)
cleanup_docker_containers
docker run -d --net host --name=consul-agent-02 gliderlabs/consul-agent -advertise $(docker-machine ip consul-agent-02) -join $(docker-machine ip consul-server-01)

print_consul_webui_endpoint
