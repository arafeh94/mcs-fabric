#!/usr/bin/env bash

function info() {
    echo -e "************************************************************\n\033[1;33m${1}\033[m\n************************************************************"
}

export DOMAIN=${DOMAIN-mcs.com}

docker_compose_args=${DOCKER_COMPOSE_ARGS:- -f docker-compose.yaml -f docker-compose-couchdb.yaml -f docker-compose-dev.yaml}

# Clean up. Remove all containers, delete local crypto material

info "Cleaning up"
./clean.sh
unset ORG COMPOSE_PROJECT_NAME

# Create orderer organization

info "Creating orderer organization for $DOMAIN"
docker-compose -f docker-compose-orderer.yaml -f docker-compose-orderer-ports.yaml up -d


api_port=${API_PORT:-4000}
www_port=${WWW_PORT:-81}
ca_port=${CA_PORT:-7054}
peer0_port=${PEER0_PORT:-7051}

export ORG=server API_PORT=4000 WWW_PORT=81 PEER0_PORT=7051 CA_PORT=7054
export COMPOSE_PROJECT_NAME=server
info "Creating member organization server with api $API_PORT"
docker-compose ${docker_compose_args} up -d
unset ORG COMPOSE_PROJECT_NAME API_PORT WWW_PORT PEER0_PORT CA_PORT


info "Adding server to the consortium"
./consortium-add-org.sh server


export ORG=server
export COMPOSE_PROJECT_NAME=server

info "Server - Creating Channels"
./channel-create.sh observations
./channel-create.sh taskpts
info "Server - Join Channels"
./channel-join.sh observations
./channel-join.sh taskpts
info "Server - Install chaincode"
./chaincode-install.sh ccobservations
./chaincode-install.sh cctaskpts
info "Server - Instantiate chaincode"
./chaincode-instantiate.sh observations ccobservations
./chaincode-instantiate.sh taskpts cctaskpts



