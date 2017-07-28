{ system ? builtins.currentSystem , crossSystem ? null, config ? {}}:
let
  /* NB that CASA  calls /bin/sh, so consistency between nixpkgs and CASA is required
  */
  pkgs = (import <nixpkgs1609>) { inherit system crossSystem config; };

  callPackage = pkgs.lib.callPackageWith (pkgs  // self);

  self = rec {

    mpich   = callPackage nix/pkgs/mpich {};  
    swift-t = callPackage nix/pkgs/swift-t {};
		     
# For easy access to consistent parent packages    
    inherit pkgs;
  };
in
    self   
    
