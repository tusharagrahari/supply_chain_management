#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a collection of bash functions used by different scripts

# imports
. scripts/utils.sh

export CORE_PEER_TLS_ENABLED=true
export ORDERER1_CA=${PWD}/organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem
export PEER0_PRODUCER_CA=${PWD}/organizations/peerOrganizations/producer.example.com/tlsca/tlsca.producer.example.com-cert.pem
export PEER0_SUPPLIER_CA=${PWD}/organizations/peerOrganizations/supplier.example.com/tlsca/tlsca.supplier.example.com-cert.pem
export PEER0_WHOLESALER_CA=${PWD}/organizations/peerOrganizations/wholesaler.example.com/tlsca/tlsca.wholesaler.example.com-cert.pem
export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer1.example.com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer1.example.com/tls/server.key

# Set environment variables for the peer org
setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  infoln "Using organization ${USING_ORG}"
  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_LOCALMSPID="ProducerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_PRODUCER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/producer.example.com/users/Admin@producer.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_LOCALMSPID="SupplierMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_SUPPLIER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/supplier.example.com/users/Admin@supplier.example.com/msp
    export CORE_PEER_ADDRESS=localhost:9051

  elif [ $USING_ORG -eq 3 ]; then
    export CORE_PEER_LOCALMSPID="WholesalerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_WHOLESALER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/wholesaler.example.com/users/Admin@wholesaler.example.com/msp
    export CORE_PEER_ADDRESS=localhost:11051
  else
    errorln "ORG Unknown"
  fi

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}

# Set environment variables for use in the CLI container
setGlobalsCLI() {
  setGlobals $1

  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_ADDRESS=peer0.producer.example.com:7051
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_ADDRESS=peer0.supplier.example.com:9051
  elif [ $USING_ORG -eq 3 ]; then
    export CORE_PEER_ADDRESS=peer0.wholesaler.example.com:11051
  else
    errorln "ORG Unknown"
  fi
}

# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode
# operation

parsePeerConnectionParameters() {
  PEER_CONN_PARMS=()
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    local USING_ORG=""
    if [ -z "$OVERRIDE_ORG" ]; then
      USING_ORG=$1
    else
      USING_ORG="${OVERRIDE_ORG}"
    fi
    
    if [ $USING_ORG -eq 1 ]; then
      PEER="peer0.producer"
      CA=PEER0_PRODUCER_CA
    elif [ $USING_ORG -eq 2 ]; then
      PEER="peer0.supplier"
      CA=PEER0_SUPPLIER_CA
    elif [ $USING_ORG -eq 3 ]; then
      PEER="peer0.wholesaler"
      CA=PEER0_WHOLESALER_CA
    else
      errorln "ORG Unknown"
    fi 
    # PEER="peer0.org$1"
    ## Set peer addresses
    if [ -z "$PEERS" ]
    then
	    PEERS="$PEER"
    else
	    PEERS="$PEERS $PEER"
    fi
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
    ## Set path to TLS certificate
    # CA=PEER0_ORG$1_CA
    TLSINFO=(--tlsRootCertFiles "${!CA}")
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" "${TLSINFO[@]}")
    # shift by one to get to the next organization
    shift
  done
}
verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}