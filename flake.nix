{
    inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    outputs = { self, nixpkgs }:

    let

        system = "x86_64-linux";
        pkgs = import nixpkgs { inherit system; };
        buildSite = import ./lib/buildSite.nix;

    in {

        packages.${system} = {

            default = buildSite {
                inherit pkgs;
                root = self.outPath;
            };

            forPages = buildSite {
                inherit pkgs;
                root = self.outPath;
                rootDir = "/rocs";
            };
        };

        apps.${system}.default = {
            type = "app";
            program = (pkgs.writeShellScript "serveFiles" ''

                cd ${self.outputs.packages.${system}.default.outPath}
                ${pkgs.python3}/bin/python -m http.server 8985

            '').outPath;
        };

        # Can I ship functions in a flake?
        lib = { inherit buildSite; };

    };
}
