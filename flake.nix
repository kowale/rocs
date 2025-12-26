{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }:

    let

      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      buildSite = import ./lib/buildSite.nix;
      buildSiteAt = rootDir: buildSite {
        inherit pkgs rootDir;
        root = self.outPath;
        local = "priv";
        css = ''/* extra css */'';
        js = ''// extra js'';
      };

    in
    {
      packages.${system} = {
        # nix build && python3 -m http.server -d result
        default = buildSiteAt "";

        # for github pages
        forPages = buildSiteAt "/rocs";
      };

      lib = { inherit buildSite buildSiteAt; };
    };
}
