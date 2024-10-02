#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# import utils
. scripts/envVar1.sh
. scripts/configUpdate.sh

# NOTE: this must be run in a CLI container since it requires jq and configtxlator 
createAnchorPeerUpdate() {
  infoln "Fetching channel config for channel $CHANNEL_NAME"
  fetchChannelConfig $ORG $CHANNEL_NAME ${CORE_PEER_LOCALMSPID}config.json

  infoln "Generating anchor peer update transaction for ${ORG_NAME} on channel $CHANNEL_NAME"

  if [ $ORG -eq 1 ]; then
    ORG_NAME="Producer"
    HOST="peer0.producer.example.com"
    PORT=7051
  elif [ $ORG -eq 2 ]; then
    ORG_NAME="Supplier"
    HOST="peer0.supplier.example.com"
    PORT=9051
  elif [ $ORG -eq 3 ]; then
    ORG_NAME="Wholesaler"
    HOST="peer0.wholesaler.example.com"
    PORT=11051
  else
    errorln "Organization $ORG unknown"
    exit 1
  fi

  set -x
  # Modify the configuration to append the anchor peer 
  jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'$HOST'","port": '$PORT'}]},"version": "0"}}' ${CORE_PEER_LOCALMSPID}config.json > ${CORE_PEER_LOCALMSPID}modified_config.json
  { set +x; } 2>/dev/null

  # Compute a config update, based on the differences between 
  # {orgmsp}config.json and {orgmsp}modified_config.json, write
  # it as a transaction to {orgmsp}anchors.tx
  createConfigUpdate ${CHANNEL_NAME} ${CORE_PEER_LOCALMSPID}config.json ${CORE_PEER_LOCALMSPID}modified_config.json ${CORE_PEER_LOCALMSPID}anchors.tx
}

updateAnchorPeer() {
  infoln "Updating anchor peer for ${ORG_NAME} on channel $CHANNEL_NAME"
  peer channel update -o orderer1.example.com:7050 --ordererTLSHostnameOverride orderer1.example.com -c $CHANNEL_NAME -f ${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile "$ORDERER_CA" >&log.txt
  res=$?
  cat log.txt
  verifyResult $res "Anchor peer update failed"
  successln "Anchor peer set for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME'"
}

# Main script execution starts here
ORG=$1
CHANNEL_NAME=$2

# Set organization-specific global variables
setGlobalsCLI $ORG

# Create the anchor peer update transaction
createAnchorPeerUpdate 

# Update the anchor peer on the channel
updateAnchorPeer
