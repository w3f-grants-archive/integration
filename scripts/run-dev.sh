#!/bin/bash

# spin up the substrate node
docker compose up substrate-node -d
echo "Waiting for the substrate node to start up..."
sleep 10

docker compose up mongodb -d
docker compose up provider-api -d

CONTAINER_NAME=$(docker ps -q -f name=provider-api)

echo "Installing packages for redspot and building"
docker exec -it $CONTAINER_NAME zsh -c 'cd /usr/src/redspot && yarn && yarn build'

echo "Installing packages for protocol, building, and deploying contract"
docker exec -it $CONTAINER_NAME zsh -c 'cd /usr/src/protocol && yarn && yarn build && { CONTRACT_ADDRESS=$(yarn deploy | tee /dev/fd/3 | grep \x27contract address:\x27 | awk -F \x27:  \x27 \x27{print $2}\x27); } 3>&1 && export CONTRACT_ADDRESS=$CONTRACT_ADDRESS'

echo "Installing packages for dapp-example, building and deploying contract"
docker exec -it $CONTAINER_NAME zsh -c 'cd /usr/src/dapp-example && yarn && yarn build && { DAPP_CONTRACT_ADDRESS=$(yarn deploy | tee /dev/fd/3 | grep \x27contract address:\x27 | awk -F \x27:  \x27 \x27{print $2}\x27); } 3>&1 && export DAPP_CONTRACT_ADDRESS=$DAPP_CONTRACT_ADDRESS'

echo "Generating provider mnemonic"
docker exec -it $CONTAINER_NAME zsh -c '/home/root/dev.dockerfile.generate.provider.mnemonic.sh'

echo "Sending funds to the Provider account and registering the provider"
docker exec -it $CONTAINER_NAME zsh -c 'yarn && yarn build && cd packages/core && yarn setup provider && yarn setup dapp'

echo "Dev env up! You can now interact with the provider-api."
docker exec -it $CONTAINER_NAME zsh
