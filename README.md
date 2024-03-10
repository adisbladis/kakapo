# Kākāpō

A web bundler for Nix strings with context.

Named after the [flightless parrot](https://www.doc.govt.nz/nature/native-animals/birds/birds-a-z/kakapo/).

## Motivation

Because I'm unwell and and think cursed hacks like [//users/sterni/nix/html/README.md](https://cs.tvl.fyi/depot/-/blob/users/sterni/nix/html/README.md) are cool and would like to make it's usage more practical.

## Basic usage

- Writing a bundle from a derivation a web root with unsubstituted store references
``` nix
let
  indexHTML = writeText "index.html" ''
    <h1>Welcome!</h1>
    <img src="${./banner.jpg}" />
  '';

  webRoot = runCommand "webroot" { } ''
    mkdir $out
    cp ${indexHTML} $out/index.html
  '';
in kakapo.makeBundle webRoot;
```

- Bundling a file tree from an attribute set
```nix
kakapo.bundleTree "my-webroot" { } {
  "index.html" = ''
    <h1>Welcome!</h1>
    <img src="${./banner.jpg}" />
  '';
}
```

## Use with `htmlNix'

Check out [./templates/htmlNix](./templates/htmlNix).
