Nix to Docker buildpack
=======================

For creating Docker containers from scratch using Nix package manager.

For more information about Nix, please, read `Domen's introduction to Nix
package manager`__.

__ https://www.domenkozar.com/2014/01/02/getting-started-with-nix-package-manager/


Example
-------

1. Build the builder Docker image

   .. code:: bash

      $ cd builder
      $ docker build -t nix-build-pack --rm=true --force-rm=true --no-cache=true .
      $ cd ..

2. Run the builder container to extract tarball for your Nix expression

   .. code:: bash

      $ docker run --rm -v `pwd`:/opt nix-build-pack /opt/pyramid.nix

3. Build the target Docker image from scratch using the created tarball

   .. code:: bash

      $ docker build -t pyramid --rm=true --force-rm=true --no-cache=true .

4. Run container from the created image as usual

   .. code:: bash

      $ docker run --rm -v `pwd`:/opt -P pyramid /opt/hello_world.py


Explained
---------

``./builder/nix-build-pack.sh`` is a simple bash script to use Nix package
manager to 1) update its package repository, 2) build the given expression with
symlinked result directory, 3) make a nice dependency graph out of it, and 4)
dump built closure containing all dependencies for the built app into a
tarball.

.. code:: bash

   #!/bin/bash
   source ~/.nix-profile/etc/profile.d/nix.sh
   nix-channel --update
   nix-build $1 -o app
   nix-store -q app --graph | dot -Tpng > $1.png
   tar cvz `nix-store -qR app` app > $1.tar.gz

The resulting tarball will contain only two root directories: ``/nix`` and
``/app``.

``./builder/Dockerfile`` is a simple example Dockerfile based on some
Nix-capable base image to be used as a builder container for creating
Nix-closure tarballs for the target images. It 1) installs Nix package manager,
and 2) adds the previous builder script as the entrypoint for the image.

.. code::

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

``./Dockerfile`` is an example Dockerfile for building the actual target
image from the resulting Nix-closure tarball. Remember to update ADD to add
your tarball (named after the original Nix expression filename), add
necessary EXPOSE, ENV and USER metadata, and update ENTRYPOINT.

.. code::

   FROM scratch
   ADD pyramid.nix.tar.gz /
   EXPOSE 8080
   ENTRYPOINT ["/app/bin/python3"]
