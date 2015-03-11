FROM debian:wheezy
RUN apt-get update && apt-get install -y curl bzip2 adduser graphviz
RUN adduser --disabled-password --gecos '' user
RUN mkdir -m 0755 /nix && chown user /nix
USER user
ENV USER user
WORKDIR /home/user
RUN curl https://nixos.org/nix/install | sh
COPY nix-build-pack.sh /home/user/
ENTRYPOINT ["/home/user/nix-build-pack.sh"]
