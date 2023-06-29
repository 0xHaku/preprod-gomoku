#!/bin/sh

forge create --rpc-url <your_rpc_url> \
    --private-key <your_private_key> \
    --etherscan-api-key <your_etherscan_api_key> \
    --verify \
    src/Factory.sol:Factory