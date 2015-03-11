with import <nixpkgs> {};

python34.buildEnv.override {
  extraLibs = [ pkgs.python34Packages.pyramid ];
  ignoreCollisions = true;
}
