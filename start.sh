#!/usr/bin/env bash

set -euo pipefail

name=db-mainnet
flake=`pwd`

if nixos-container status "$name"; then
    echo "Updating"
    nixos-container update "$name" --flake "$flake"
else
    echo "Creating"
    nixos-container create "$name" --flake "$flake" "$@"
fi

nixos-container start "$name"
