#!/bin/bash

# import utils
source scripts/envVar.sh

# Accept the organization and peer as arguments
ORG=$1    # Organization number (1 for Producer, 2 for Supplier, 3 for Wholeseller)
PEER=$2   # Peer number (0 for peer0, 1 for peer1)

# Set the environment for the specified organization and peer
setGlobals $ORG $PEER
cp ../config/core.yaml ./configtx/.
