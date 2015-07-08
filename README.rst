README
======


1. Build the builder

   .. code:: bash

      $ cd builder && docker build -t nix-build-pack --rm=true --force-rm=true --no-cache=true .

2. Run the builder to extract tarball

   .. code:: bash

      $ docker run --rm -v `pwd`:/opt/ nix-build-pack /opt/pyramid.nix

3. Build the final container with the created tarball

   .. code:: bash

      $ docker build -t pyramid --rm=true --force-rm=true --no-cache=true .

4. Use the built container

   .. code:: bash

      $ docker run --rm -v `pwd`:/opt/ -P pyramid /opt/hello_world.py
