#!/usr/bin/env bash

# free up some space on the system
docker system prune -f

# load env file
export $(grep -v '^#' env/development.env | xargs -0);

# create the docker database mount dir if not exists
mkdir -p ".$MONGO_DATA_DIR"

# first leave the existing swarm
docker swarm leave --force;

# init the swarm and expose elastic ip
docker swarm init --advertise-addr 127.0.0.1;

# get the join token and store it in the environment files
SWARM_JOIN_TOKEN_WORKER=$(docker swarm join-token worker -q);
sed -i '/SWARM_JOIN_TOKEN_WORKER=/d' ./env/development.env
echo -e "\n\nSWARM_JOIN_TOKEN_WORKER=$SWARM_JOIN_TOKEN_WORKER" >> ./env/development.env

# we need a login to pull a private image from docker hub
docker login --username $DOCKER_USER --password "$DOCKER_PASS";

# build local docker images from respective docker files

docker build --tag frontend:latest --file frontend/Dockerfile frontend/

docker build --tag scheduler:latest --file scheduler/Dockerfile .

docker build --tag api:latest --file Dockerfile .

docker stack deploy --with-registry-auth --compose-file docker-compose.yml --compose-file docker-compose.dev.yml "$DOCKER_STACK_NAME";

# wait a bit before we show debug logs
sleep 1
docker service ls
docker stack ps Master

