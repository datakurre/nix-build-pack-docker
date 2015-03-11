#!/bin/bash
source ~/.nix-profile/etc/profile.d/nix.sh
nix-channel --update
nix-build $1
nix-store -q result --graph | dot -Tpng > $1.png
tar cvz `nix-store -qR result` result > $1.tar.gz
