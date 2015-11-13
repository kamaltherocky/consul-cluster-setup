#! /bin/bash

##### Global Variables
CONSUL_CLUSTER_SIZE=3
CONSUL_AGENTS=2

#### Functions

function cleanup_docker_containers() {
  # Kill and remove containers on the node
  if [ $(docker ps -q | wc -l) > 0 ]; then
    docker kill $(docker ps -q)
  fi

  if [ $(docker ps -aq | wc -l) > 0 ]; then
    docker rm $(docker ps -aq)
  fi
}

function run_consul_server() {
  eval $(docker-machine env $1)
  cleanup_docker_containers
  if [ "$2" = "1" ]; then
    docker run -d --net host --name=$1 gliderlabs/consul-server -advertise $(docker-machine ip $1) -bootstrap-expect=3
  else
    docker run -d --net host --name=$1 gliderlabs/consul-server -advertise $(docker-machine ip $1) -join $(docker-machine ip consul-server-01)
  fi

}

function run_consul_agent() {
  eval $(docker-machine env $1)
  cleanup_docker_containers
  docker run -d --net host --name=$1 gliderlabs/consul-agent -advertise $(docker-machine ip $1) -join $(docker-machine ip consul-server-01)
}


function create_and_configure_host() {
  # create a node using docker-machine
  docker-machine create --driver virtualbox $1
  # Start the node if it is not Running
  docker-machine start $1
  # Install Python in Boot2Docker VM
  docker-machine ssh $1 "tce-load -w -i python.tcz"
  # add python symbolic link in /usr/bin/python as ansible looks at that location
  docker-machine ssh $1 "sudo ln -s /usr/local/bin/python /usr/bin/python"
  # Install pip and docker-py in boot2docker VM
  docker-machine ssh $1 "rm -rf get-pip.py && wget https://bootstrap.pypa.io/get-pip.py && sudo python get-pip.py && sudo pip install docker-py"
}

function create_consul_cluster() {
  # Consul Server Cluster using docker machine
  INDEX_START=1
  INDEX_FINISH=$CONSUL_CLUSTER_SIZE
  SERVER_NAME=""
  for i in $(eval echo "{$INDEX_START..$INDEX_FINISH}")
  do
    SERVER_NAME="consul-server-0$i"
  	create_and_configure_host $SERVER_NAME
    run_consul_server $SERVER_NAME "$i"
  done
}

function create_consul_agents() {
  # Consul Agents using docker macine
  # Consul Server Cluster using docker machine
  INDEX_START=1
  INDEX_FINISH=$CONSUL_AGENTS
  SERVER_NAME=""
  for i in $(eval echo "{$INDEX_START..$INDEX_FINISH}")
  do
    SERVER_NAME="consul-agent-0$i"
  	create_and_configure_host $SERVER_NAME
    run_consul_agent $SERVER_NAME
  done
}

function print_consul_webui_endpoint() {
  echo "Consul Cluster Web UI URL :"
  echo "---------------------------"
  echo "http://$(docker-machine ip consul-server-01):8500/ui"
  echo "http://$(docker-machine ip consul-server-02):8500/ui"
  echo "http://$(docker-machine ip consul-server-03):8500/ui"
}


##### MAIN SCRIPT #############
create_consul_cluster
create_consul_agents
print_consul_webui_endpoint
