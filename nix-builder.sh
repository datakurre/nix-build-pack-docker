#!/bin/bash
source ~/.nix-profile/etc/profile.d/nix.sh
mkdir tmp
nix-channel --update
nix-build $1
nix-store -q result --graph | sed 's/#ff0000/#ffffff/' | dot -Nstyle=bold -Tpng > $1.png
tar cvz --transform="s|^result/bin|bin|" \
        --transform="s|^result|usr/local|" \
        tmp `nix-store -qR result` result/* > $1.tar.gz
