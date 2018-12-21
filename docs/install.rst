.. _installation:

Installation
============

This page explains how to install the hexabomb game and the packages around it.
Most of the programs and libraries are available in the package registers of
the languages they are written in.
For more convenience, most of the tools are also packaged in the netorcaipkgs_
Nix_ repository, which allows to install all of them with the same interface.
The concerned software is the following.

- hexabomb, the game itself.
- netorcai, the network orchestrator. **Required to host a game**.
- netorcai client libraries. **Required to run bots that play the game**.
- hexabomb-visu, a visualization client. **Required to visualize games**.

From nix
--------
Nix_ is a package manager with amazing properties that is available on
Linux-like systems.
It stores all the packages in a dedicated directory (usually :code:`/nix/store`),
which avoids interfering with classical system packages (usually in :code:`/usr`).

Once Nix is installed on your machine (instructions on `Nix's web page <Nix_>`_),
packages can be installed with :code:`nix-env --install` (:code:`-i`).
Several installation command examples are given below.

.. code-block:: bash

    # install hexabomb and netorcai
    nix-env -f https://github.com/netorcai/netorcaipkgs/archive/master.tar.gz -iA hexabomb netorcai

    # only install the hexabomb game
    nix-env -f https://github.com/netorcai/netorcaipkgs/archive/master.tar.gz -iA hexabomb # latest release
    nix-env -f https://github.com/netorcai/netorcaipkgs/archive/master.tar.gz -iA hexabomb_dev # or latest commit

    # only install the netorcai orchestrator
    nix-env -f https://github.com/netorcai/netorcaipkgs/archive/master.tar.gz -iA netorcai

    # install the desired client libraries
    nix-env -f https://github.com/netorcai/netorcaipkgs/archive/master.tar.gz -iA netorcai_client_cpp

The programs should then be callable directly — e.g., :code:`netorcai --help`.

Uninstalling can be done with :code:`nix-env --uninstall`
(:code:`-e`) — e.g., :code:`nix-env -e hexabomb '.*netorcai.*'`.

From package registers
----------------------

hexabomb
~~~~~~~~
The hexabomb game is developed in D_ and can be installed with dub_.
First install a `D compiler`_ and dub.
You can then directly run the latest release of hexabomb with
:code:`dub run hexabomb`.
The following commands produce a standalone executable.

.. code-block:: bash

    dub fetch --cache=local hexabomb
    cd hexabomb-*/hexabomb
    dub build
    ./hexabomb --help

netorcai
~~~~~~~~
The netorcai orchestrator is developed in Go_ and can be installed with the
`go command`_. Install a recent Go version then run
:code:`go get github.com/netorcai/netorcai/cmd/netorcai` to retrieve the executable in
:code:`${GOPATH}/bin` (if the :code:`GOPATH` environment variable is unset,
it should default to :code:`${HOME}/go` or :code:`%USERPROFILE%\go`).

.. code-block:: bash

    go get github.com/netorcai/netorcai/cmd/netorcai
    ${GOPATH:-${HOME}/go}/bin/netorcai --help


D client library
~~~~~~~~~~~~~~~~
The library is released on the
`D package registry <https://code.dlang.org/packages/netorcai-client>`_.
Documentation and usage with dub_ are given there.

Build it yourself
-----------------
All the projects that have been developed around hexabomb are open source and
can be built and installed manually.
Please refer to the documentation of the different projects for building
instructions.
All these projects are hosted on the `netorcai GitHub organization`_.

.. _netorcaipkgs: https://github.com/netorcai/pkgs
.. _Nix: https://nixos.org/nix/
.. _D: https://dlang.org/
.. _dub: https://code.dlang.org/getting_started
.. _D compiler: https://dlang.org/download.html
.. _Go: https://golang.org/
.. _go command: https://golang.org/cmd/go/
.. _netorcai GitHub organization: https://github.com/netorcai
