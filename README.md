### Running a Consul Cluster with few Agents

#### Pre-Requisite

- docker-machine ( Mac OS : brew install docker-machine )
- docker ( Mac OS :  brew install docker )

#### Running the script

Shell script

./cluster_setup.sh

Ansible

ansible-playbook --private-key /Users/kmuralidharan/.docker/machine/machines/consul-agent-01/id_rsa -u docker -i hosts -vvv test.yml

#### TODO

- Add support for additional providers like AWS, Openstack
- Add support for taking the Cluster Size and number of Agents
- Optimize the code to use the above data rather than being static
- Add Test Cases to run on the cluster
