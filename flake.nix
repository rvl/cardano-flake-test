{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.03";
  inputs.cardano-node.url = "github:input-output-hk/cardano-node/1.26.2";
  inputs.cardano-db-sync.url = "github:input-output-hk/cardano-db-sync/9.0.0";

  outputs = { self, nixpkgs }: {

    nixosConfigurations.container = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules =
        [ ({ pkgs, ... }: {
            boot.isContainer = true;

            # Let 'nixos-version --json' know about the Git revision
            # of this flake.
            system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;

            # Network configuration.
            networking.useDHCP = false;
            networking.firewall.allowedTCPPorts = [ 5432 ];

            services.postgresql = {
              enable = true;
            };

            services.cardano-db-sync = {
              enable = true;
              cluster = "testnet";
              socketPath = config.services.cardano-node.socketPath;
            };

            services.cardano-node = {
              enable = true;
              environment = "testnet";
              socketPath = "/var/run/cardano-node/cardano-node.socket";
              
          })
        ];
    };

  };
}
