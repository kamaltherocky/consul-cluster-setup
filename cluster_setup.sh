#! /bin/bash

# Clean everthing

# docker-machine kill $(docker-machine ls --filter name=consul*)

create_consul_cluster() {
  # Consul Server Cluster using docker macine
  docker-machine create --driver virtualbox consul-server-01
  docker-machine create --driver virtualbox consul-server-02
  docker-machine create --driver virtualbox consul-server-03
}

create_consul_agents() {
  # Consul Agents using docker macine
  docker-machine create --driver virtualbox consul-agent-01
  docker-machine create --driver virtualbox consul-agent-02
}

cleanup_docker_containers() {
  # Kill and remove containers on the node
  docker kill $(docker ps -q)
  docker rm $(docker ps -aq)
}

create_consul_cluster
create_consul_agents
# Start Consul Docker containers on the created nodes
# Bootstrap Consul Server
eval $(docker-machine env consul-server-01)
cleanup_docker_containers
docker run -d --net host --name=consul-server-01 gliderlabs/consul-server -advertise $(docker-machine ip consul-server-01) -bootstrap

eval $(docker-machine env consul-server-02)
cleanup_docker_containers
docker run -d --net host --name=consul-server-02 gliderlabs/consul-server -advertise $(docker-machine ip consul-server-02) -join $(docker-machine ip consul-server-01)

eval $(docker-machine env consul-server-03)
cleanup_docker_containers
docker run -d --net host --name=consul-server-03 gliderlabs/consul-server -advertise $(docker-machine ip consul-server-03) -join $(docker-machine ip consul-server-01)

# Stop the Bootstrap and Join the cluster as Normal Server
eval $(docker-machine env consul-server-01)
cleanup_docker_containers
docker run -d --net host gliderlabs/consul-server -advertise $(docker-machine ip consul-server-01)  -join $(docker-machine ip consul-server-02)

# Start Consul Agent and Join the Consul Cluster
eval $(docker-machine env consul-agent-01)
cleanup_docker_containers
docker run -d --net host --name=consul-agent-01 gliderlabs/consul-agent -advertise $(docker-machine ip consul-agent-01) -join $(docker-machine ip consul-server-01)

eval $(docker-machine env consul-agent-02)
cleanup_docker_containers
docker run -d --net host --name=consul-agent-02 gliderlabs/consul-agent -advertise $(docker-machine ip consul-agent-02) -join $(docker-machine ip consul-server-01)

echo "Consul Cluster Web UI URL :"
echo "http://$(docker-machine ip consul-server-01):8500/ui"
