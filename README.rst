Nix to Docker buildpack
=======================

For creating Docker containers from scratch using Nix_ package manager.

Please, read `Domen's introduction to Nix package manager`__, for more
information about Nix.

.. _Nix: https://nixos.org/nix/
__ https://www.domenkozar.com/2014/01/02/getting-started-with-nix-package-manager/


Try it
------

.. code:: bash

   $ git clone https://github.com/datakurre/nix-build-pack-docker
   $ cd nix-build-pack-docker
   $ make

Then use ``docker ps`` (and ``docker-machine ip default`` on mac) to
figure out, where the example Pyramid service is running.


Step by step
------------

At first, create a generic Nix-builder image and name it
*nix-builder*:

.. code:: bash

    $ docker build -t nix-builder -f nix-builder.docker --rm=true --force-rm=true --no-cache=true .

The builder is made of simple single-user Nix installation on top of some
trusted Linux distribution, like debian:

.. code:: Dockerfile

    FROM debian:jessie
    RUN apt-get update && apt-get install -y curl bzip2 adduser graphviz
    RUN adduser --disabled-password --gecos '' user
    RUN mkdir -m 0755 /nix && chown user /nix
    USER user
    ENV USER user
    WORKDIR /home/user
    RUN curl https://nixos.org/nix/install | sh
    VOLUME /nix
    COPY nix-builder.sh /home/user/
    ENTRYPOINT ["/home/user/nix-builder.sh"]

The image contains a mount point at ``/nix`` to support shared persistent
Nix-store as a data container for any amount of builder containers.

The entrypoint is a simple script to build a Nix expression and

* add ``/tmp``, because that's usually required in images
* move ``bin`` directory from build results into root
* move other build result directories into ``/usr/local``.

.. code:: bash

    #!/bin/bash
    source ~/.nix-profile/etc/profile.d/nix.sh
    mkdir tmp
    nix-channel --update
    nix-build $1
    nix-store -q result --graph | sed 's/#ff0000/#ffffff/' | dot -Nstyle=bold -Tpng > $1.png
    tar cvz --transform="s|^result/bin|bin|" \
            --transform="s|^result|usr/local|" \
            tmp `nix-store -qR result` result/* > $1.tar.gz

These build conventions work for me, but the script should be trivial
enough to customize.

Once the builder is build, a data container to persist Nix-store between
builds (and allow parallel builds with shared store) is created with:

.. code:: bash

    $ docker create --name nix-store nix-builder

Now you can run the builder for your expression with:

.. code:: bash

    $ docker run --rm --volumes-from=nix-store -v $PWD:/mnt nix-builder /mnt/pyramid.nix

The example ``pyramid.nix`` expression simply defines a Python environment
with pyramid-package:

.. code:: nix

    with import <nixpkgs> {};

    python.buildEnv.override {
      extraLibs = [ pkgs.pythonPackages.pyramid ];
      ignoreCollisions = true;
    }

The builder creates a tarball, which could be used in ``./Dockerfile`` to
populate an image from scratch:

.. code:: Dockerfile

    FROM scratch
    ADD pyramid.nix.tar.gz /
    EXPOSE 8080
    ENTRYPOINT ["/bin/python"]

with a normal docker build command:

.. code::

    $ docker build -t pyramid --rm=true --force-rm=true --no-cache=true .

Finally, the resulting Docker image can be used to Run containers as usual:

.. code:: bash

    $ docker run --rm -v $PWD:/mnt -w /mnt -P pyramid hello_world.py
