.. _installation:

Installation
============

This page explains how to install the hexabomb game.
To visualize games, please refer to the `hexabomb visualization client`_.

As hexabomb requires netorcai, you should also install netorcai and probably
some netorcai client libraries.
Please refer to the `netorcai documentation`_ for this.

Build the game
--------------
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

.. _netorcaipkgs: https://github.com/netorcai/pkgs
.. _netorcai documentation: https://netorcai.readthedocs.io
.. _D: https://dlang.org/
.. _dub: https://code.dlang.org/getting_started
.. _D compiler: https://dlang.org/download.html
.. _hexabomb visualization client: https://github.com/netorcai/hexabomb-visu
