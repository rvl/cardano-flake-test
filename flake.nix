{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.03";
  inputs.cardano-node.url = "github:input-output-hk/cardano-node/1.27.0";
  inputs.cardano-db-sync.url = "github:input-output-hk/cardano-db-sync";

  outputs = { self, nixpkgs, cardano-node, cardano-db-sync }: let
    environment = "mainnet";
  in {
    nixosConfigurations.container = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
          cardano-db-sync.nixosModules.cardano-db-sync
          cardano-node.nixosModules.cardano-node

          ({ pkgs, config, ... }: {
            boot.isContainer = true;

            # Network configuration.
            networking = {
              useDHCP = false;
              resolvconf.enable = true;
              useHostResolvConf = false;
              defaultGateway = "10.240.1.1";
              nameservers = [ config.networking.defaultGateway.address ];
              interfaces.eth0.ipv4.addresses = [ {
                address = "10.240.1.2";
                prefixLength = 24;
              } ];
              firewall.allowedTCPPorts = [ 5432 ];
            };

            services.postgresql = {
              enable = true;
              enableTCPIP = true;
              # log in with psql -h 10.240.1.2 cdbsync cdbsync
              authentication = ''
                host ${config.services.cardano-db-sync.postgres.database} ${config.services.cardano-db-sync.postgres.user} ${config.networking.defaultGateway.address}/32 trust
              '';
              ensureDatabases = [ config.services.cardano-db-sync.postgres.database ];
              ensureUsers = [ {
                name = config.services.cardano-db-sync.postgres.user;
                 ensurePermissions = {
                   "DATABASE ${config.services.cardano-db-sync.postgres.database}" = "ALL PRIVILEGES";
                 };
              } ];
            };

            # ensure database and user are created before starting 
            systemd.services.cardano-db-sync.after = [
              "postgresql.service"
              "cardano-node.service"
            ];

            services.cardano-db-sync = {
              enable = true;
              cluster = environment;
              socketPath = config.services.cardano-node.socketPath;
            };

            services.cardano-node = {
              enable = true;
              inherit environment;
              systemdSocketActivation = true;
            };

            # Let cardano-db-sync use the cardano-node socket file
            users.users.${config.services.cardano-db-sync.user} = {
              extraGroups = [ "cardano-node" ];
            };

            # Let 'nixos-version --json' know about the Git revision
            # of this flake.
            system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
          }) ];
    };
  };
}
