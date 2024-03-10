{ pkgs ? import <nixpkgs> { } }:

let
  inherit (pkgs) callPackage writeText runCommand;
  kakapo = callPackage ./. { };

  myAsset = writeText "my-asset.txt" ''
    hello world!
  '';

in {
  makeBundle = let
    indexHTML = writeText "index.html" ''
      <a href="${myAsset}">my-asset.txt</a>
    '';

    webRoot = runCommand "webroot" { } ''
      mkdir $out
      cp ${indexHTML} $out/index.html
    '';
  in kakapo.makeBundle webRoot;

  bundleTree = kakapo.bundleTree "my-webroot" { } {
    "index.html" = ''
      <a href="/about.html">about</a>
      <a href="/blog/posts/0.html">about</a>
    '';
    "about.html" = pkgs.writeText "about.html" ''
      <p>About us</p>
    '';
    blog.posts."0.html" = ''
      <p>Welcome to my blog</p>
      <a href="${myAsset}">my asset</a>
    '';
  };
}
