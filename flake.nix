{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";
  inputs.cardano-node.url = "github:input-output-hk/cardano-node/1.27.0";
  inputs.cardano-db-sync.url = "github:input-output-hk/cardano-db-sync";

  outputs = { self, nixpkgs, cardano-node, cardano-db-sync }: let
    environment = "mainnet";
    pgAllowHost = "0.0.0.0/0";
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
              useDHCP = true;
              resolvconf.enable = true;
              useHostResolvConf = false;
              firewall.allowedTCPPorts = [ config.services.postgresql.port ];
            };

            services.postgresql = {
              enable = true;
              enableTCPIP = true;
              # Completely disable auth for the database so we can:
              #   psql -U cdbsync -h $container_ip cdbsync
              authentication = ''
                host ${config.services.cardano-db-sync.postgres.database} ${config.services.cardano-db-sync.postgres.user} ${pgAllowHost} trust
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
              isNormalUser = true; # workaround for 21.05
              extraGroups = [ "cardano-node" ];
            };

            # workaround required for 21.05
            users.users.cardano-node.isNormalUser = true;

            # Let 'nixos-version --json' know about the Git revision
            # of this flake.
            system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
          }) ];
    };
  };
}
