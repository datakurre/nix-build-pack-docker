#!/bin/bash
source ~/.nix-profile/etc/profile.d/nix.sh
nix-channel --update
nix-build $1
tar cvz `nix-store -qR result` result > $1.tar.gz
