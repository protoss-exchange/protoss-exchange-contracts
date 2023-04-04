#!/bin/bash

set -e

ACCOUNT_ADDRESS=0x076b885Ca6e863346774BEaF32f8752db6af9eEBEc2A9CB0D321725Cad6c197e
NETWORK=testnet

echo "Building..."
protostar build

# declare pair
echo "Declaring pair..."
DECLARE_OUTPUT=$(protostar declare ./build/protoss_pair.json --network $NETWORK --max-fee auto --json)
PAIR_CLASS_HASH=$(python -c "import sys, json; print(json.loads(sys.argv[1])['class_hash'])" $DECLARE_OUTPUT)
echo "pair class hash: $PAIR_CLASS_HASH"

echo "Declaring factory..."
DECLARE_OUTPUT=$(protostar declare ./build/protoss_factory.json --network $NETWORK --max-fee auto --json)
FACTORY_CLASS_HASH=$(python -c "import sys, json; print(json.loads(sys.argv[1])['class_hash'])" $DECLARE_OUTPUT)
echo "factory class hash: $FACTORY_CLASS_HASH"

echo "Deploying factory..."
DEPLOY_OUTPUT=$(protostar deploy $FACTORY_CLASS_HASH --inputs $PAIR_CLASS_HASH $ACCOUNT_ADDRESS --max-fee auto --network $NETWORK  --json)
FACTORY_CONTRACT_ADDRESS=$(python -c "import sys, json; print(json.loads(sys.argv[1])['contract_address'])" $DEPLOY_OUTPUT)
echo "factory contract address: $FACTORY_CONTRACT_ADDRESS"

echo "Declare router..."
DECLARE_OUTPUT=$(protostar declare ./build/protoss_router.json --max-fee auto --network $NETWORK --json)
ROUTER_CLASS_HASH=$(python -c "import sys, json; print(json.loads(sys.argv[1])['class_hash'])" $DECLARE_OUTPUT)
echo "router class hash: $ROUTER_CLASS_HASH"

echo "Deploying router..."
DEPLOY_OUTPUT=$(protostar deploy $ROUTER_CLASS_HASH --inputs $FACTORY_CONTRACT_ADDRESS $PAIR_CLASS_HASH --max-fee auto --network $NETWORK --json)
ROUTER_CONTRACT_ADDRESS=$(python -c "import sys, json; print(json.loads(sys.argv[1])['contract_address'])" $DEPLOY_OUTPUT)
echo "router contract address: $ROUTER_CONTRACT_ADDRESS"
