FROM busybox
ADD pyramid.nix.tar.gz /
EXPOSE 8080
ENTRYPOINT ["/result/bin/python3"]
