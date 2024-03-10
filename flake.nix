{
  description = "A Nix web bundler";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: (
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    {
      checks =
        forAllSystems
          (
            system:
            let
              pkgs = nixpkgs.legacyPackages.${system};
            in
            pkgs.callPackages ./test.nix { }
          );

      legacyPackages =
        forAllSystems
          (
            system:
            let
              pkgs = nixpkgs.legacyPackages.${system};
            in
            pkgs.callPackages ./default.nix { }
          );
    }
  );
}
