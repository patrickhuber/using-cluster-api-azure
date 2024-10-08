#!/usr/bin/env bash
set -e
export VERSION="4.2.0"
export BINARY="yq_linux_amd64"
curl -L https://github.com/mikefarah/yq/releases/download/v${VERSION}/${BINARY} -o yq
chmod +x yq
cp yq /usr/local/bin
rm yq