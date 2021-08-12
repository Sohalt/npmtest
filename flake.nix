{
  description = "Content management system for open local knowledge";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-21.05";

  inputs.npmlock2nix = {
    #url = "github:tweag/npmlock2nix";
    url = "/home/sohalt/projects/summer-of-nix/npmlock2nix";
    flake = false;
  };

  outputs = { self, nixpkgs, npmlock2nix }:
    let

      # Generate a user-friendly version numer.
      version = "1.0.0";

      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

    in

    {

      # A Nixpkgs overlay.
      overlay = final: prev: {

        npmtest = with final; (import npmlock2nix {pkgs = final;}).build rec {
          name = "npmtest-${version}";

          src = ./.;

          buildInputs = [ git clojure ];

          node_modules_mode = "copy";

          installPhase = ''
            clj -A:shadow-cljs -m shadow.cljs.devtools.cli release app
            mkdir -p release/js
            cp -r resources/public/* release/
            cp target/js/main.js release/js/main.js
          '';
        };

      };

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        {
          inherit (nixpkgsFor.${system}) npmtest;
        });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.npmtest);

    };
}
