with import <nixpkgs> {};

python.buildEnv.override {
  extraLibs = [ pkgs.pythonPackages.pyramid ];
  ignoreCollisions = true;
}
