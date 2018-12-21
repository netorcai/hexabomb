Example player clients
----------------------

To avoid the need of implementing bots from scratch,
naive bots implementations are provided in several languages.
All the bots should be very similar in design.

- Use the netorcai client library of the target language (see :ref:`installation`).
- Parse hexabomb game-dependent content in a dedicated *module*, and
  provide data structures corresponding to hexabomb entities (characters, bombs...).
- Provide a basic *main* file that reads and sends valid netorcai messages,
  taking random decisions for the characters that belong to the bot.

All example bots are located in the ``bots`` directory of the `hexabomb git repository`_.
The source code of each bot should be documented.
Instructions for installation, execution and dependencies installation should be in the ``README`` of each bot.

.. _hexabomb git repository: https://github.com/netorcai/hexabomb
