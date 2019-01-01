Launching your first game
=========================

Prerequisites
-------------

Some programs and libraries must be installed before launching your first game.

- netorcai (network server). Please refer to `netorcai's installation documentation`_ for this.
- hexabomb (game logic). See :ref:`installation`.
- hexabomb-visu (visualization client). Please refer to `hexabomb-visu's README`_ for this.

You should also decide in which language your bot will be implemented.
Some `netorcai client libraries`_ have been implemented in several languages
to help you build your bot.
If you do want to implement your bot in an unsupported language, please refer to
`netorcai's metaprotocol documentation`_ to implement your own library.

Running the game server
-----------------------

The netorcai_ program is in charge of this.
This program must be started first, as all the other ones connect to it.
If it is installed correctly, just run :code:`netorcai` to run it.
Some of the game parameters can be tuned by netorcai's command-line interface,
please refer to :code:`netorcai --help` to list the tunable parameters.

Running the game logic
----------------------

The hexabomb program is in charge of this.
It can be executed with :code:`hexabomb MAP`, where :code:`MAP` is a map filename.
Map files are available in `hexabomb's git repository`_.
Please refer to :code:`hexabomb --help` for a list of hexabomb command-line options.

Running the visualization
-------------------------

The `hexabomb-visu`_ program does this.
It can simply be executed with :code:`hexabomb-visu`.
Once again, more options are available (see :code:`hexabomb-visu --help`).

Running example bots
--------------------

How to run the bot highly depends on the selected language.
Example bots and instructions on how to run them can be found in
the :code:`bots` directory of `hexabomb's git repository`_.

.. note::

    You are completely free to hack these example bots as a starting point to
    implement your own bot, as they are unlicensed_.

Starting the game
-----------------

The netorcai program has an interactive prompt.
You can type :code:`help` in it to list available commands.
The :code:`start` command should run the game.

.. note::

    If you want the game to start automatically once all expected clients are
    connected, you may be interested in netorcai's :code:`--autostart` option.

.. _netorcai: https://netorcai.readthedocs.io
.. _netorcai client libraries: https://netorcai.readthedocs.io/en/latest/clients.html
.. _netorcai's installation documentation: https://netorcai.readthedocs.io/en/latest/install.html
.. _netorcai's metaprotocol documentation: https://netorcai.readthedocs.io/en/latest/metaprotocol.html
.. _hexabomb's git repository: https://github.com/netorcai/hexabomb
.. _hexabomb-visu: https://github.com/netorcai/hexabomb-visu
.. _hexabomb-visu's README: https://github.com/netorcai/hexabomb-visu
.. _unlicensed: http://unlicense.org/
