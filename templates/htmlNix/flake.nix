{
  description = "A basic website defined in Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    htmlNix = {
      type = "git";
      url = "https://code.tvl.fyi/depot.git:workspace=users/sterni/nix/html.git";
      flake = false;
    };
    kakapo = {
      url = "github:adisbladis/kakapo";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, kakapo, ... }@inputs: (
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    {
      packages =
        forAllSystems
          (
            system:
            let
              pkgs = nixpkgs.legacyPackages.${system};
            in
            {
              default = pkgs.callPackage ./. {
                htmlNix = import inputs.htmlNix { };
                kakapo = kakapo.legacyPackages.${system};
              };
            }
          );
    }
  );
}
