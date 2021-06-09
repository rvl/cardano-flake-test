# Nix flakes example - `cardano-db-sync` container

## Requirements

Follow [this guide](https://www.tweag.io/blog/2020-07-31-nixos-flakes/) and try the
example. If that works then this flake should also work.

I'm not sure whether it's necessary to have NixOS installed, or just
`nixUnstable` with flakes enabled.

## Starting

You need to already have a bridge interface with DHCP server and
internet access. Perhaps if you have docker running you can use
`docker0` for this -- I'm not sure.

```shell
host$ sudo ./start.sh --bridge br0
```

It will print the container IP after starting. Put that in a shell
variable.

```shell
host$ export container_ip=10.240.1.2
```

## Accessing the database

```shell
host$ psql -U cdbsync -h $container_ip cdbsync
```

## Backing up the database

```shell
host$ pg_dump -U cdbsync -h $container_ip cdbsync > ~/iohk/blockchains/dbsync/cdbsync.sql
```

## Restoring the database

```shell
host$ sudo nixos-container root-login db-mainnet

[root@nixos:~]# su postgres -s /run/current-system/sw/bin/bash

[postgres@nixos:/root]$ dropdb cdbsync

[postgres@nixos:/root]$ createdb cdbsync

[postgres@nixos:/root]$ exit

[root@nixos:~]# logout

host$ psql -h $container_ip cdbsync cdbsync < ~/iohk/blockchains/dbsync/cdbsync.sql
```

## Backing up the chain

TODO
