#!/usr/bin/env bash

set -euo pipefail

name=db-mainnet
flake=`pwd`

if nixos-container status "$name"; then
    echo "Updating"
    nixos-container update "$name" --flake "$flake"
else
    echo "Creating"
    nixos-container create "$name" --flake "$flake" \
        --local-address 10.240.1.2 --host-address 10.240.1.1
fi

nixos-container start "$name"
