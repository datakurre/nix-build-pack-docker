#!/bin/bash
source ~/.nix-profile/etc/profile.d/nix.sh
nix-channel --update
nix-build $1 -o app
nix-store -q app --graph | dot -Tpng > $1.png
tar cvz `nix-store -qR app` app > $1.tar.gz
