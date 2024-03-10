{ runCommand
, python3
, lib
}:

let
  inherit (lib) fix mapAttrs isDerivation isAttrs isString;
in

fix (self: {
  /*
    Make a bundle with all Nix store references of `root` substituted
    with a new internal store located at $out/_store.
  */
  makeBundle =
    root:
    assert isDerivation root;
    runCommand "${root.name}-bundle" {
      dontUnpack = true;
      dontConfigure = true;
      nativeBuildInputs = [ python3 ];
      exportReferencesGraph = [ "graph" root ];
      inherit (root) meta;
      passthru = root.passthru or { };
    } ''
      cp -r ${root} $out
      chmod +w -R $out
      python3 ${./make-bundle.py} graph $out
    '';

  /*
    Create a file tree from an attribute set of strings & derivations.

    If a string is encountered it will be written to the output as-is.
    If a derivation is encountered it will be copied to the output.

    # Example

    ```nix
    bundleTree "my-webroot" { meta.license = lib.licenses.mit; } {
      "index.html" = ''
        <a href="/about.html">about</a>
      '';
      "about.html" = pkgs.writeText "about.html" ''
        <p>About us</p>
      '';
    }
    =>
    «derivation /nix/store/190nn2hhqah4r3s3bxvfz0ms6r5i5v0j-my-webroot.drv»
    ```
  */
  bundleTree = name: attrs: tree: let
    mapTree = mapAttrs (name: value': rec {
      type =
        if isDerivation value' then "derivation"
        else if isAttrs value' then "set"
        else if isString value' then "string"
        else throw "Unsupported type in tree";
      value = if type != "set" then value' else mapTree value';
    });
    drv =
      runCommand
      name
      (attrs // {
        __structuredAttrs = true;
        tree = mapTree tree;
        passthru = attrs.passthru or { } // {
          tree = tree;
        };
      })
      "${python3.interpreter} ${./bundle-tree.py} .attrs.json $out";
  in self.makeBundle drv;

})
