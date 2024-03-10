{ htmlNix, kakapo, writeText }:
let
  inherit (htmlNix) withDoctype esc __findFile;

  asset = writeText "asset.txt" ''
    Example asset. This could be any arbitrary derivation.
  '';

in
kakapo.bundleTree "my-webroot" { } {
  "index.html" = (
    withDoctype (<html> { } [
      (<head> { } [
        (<meta> { charset = "utf-8"; } null)
        (<title> { } (esc "hello world"))
      ])
      (<body> { } [
        (<h1> { } (esc "hello world"))
        (<a> { href = asset; } (esc "example asset"))
      ])
    ])
  );
}
