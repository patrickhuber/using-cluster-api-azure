#!/bin/bash
set -e
dir=$(dirname "$0")
root=$(realpath $dir "..")

# create rsa keys for federated managed identity
if [ -v SERVICE_ACCOUNT_SIGNING_KEY_FILE ]; then
  if [ ! -f $(realpath sa.key) ]; then
    openssl genrsa -out sa.key 2048
  fi  
  if [ ! -f $(realpath sa.pub) ]; then
    openssl rsa -in sa.key -pubout -out sa.pub
  fi  
  export SERVICE_ACCOUNT_SIGNING_KEY_FILE=$(realpath sa.key)
  export SERVICE_ACCOUNT_KEY_FILE=$(realpath sa.pub)
fi

