Changelog
=========

All notable changes to this project will be documented in this file.
The format is based on `Keep a Changelog`_.
hexabomb adheres to `Semantic Versioning`_ and its public API includes the
following.

- hexabomb's command-line interface.
- hexabomb's game-dependent protocol (that uses the `netorcai metaprotocol`_).
- hexabomb's game rules and their implementation.

`Unreleased`_
-------------

Changed game rules
~~~~~~~~~~~~~~~~~~

- Characters can no longer be revived right away after being killed.
- Walls have been removed, as they were equivalent to an absence of cell.
- The game state format is now the same in `DO_INIT_ACK` and `DO_TURN_ACK`.

0.1.0 - 2018-10-30
------------------

-  Initial release.

.. _Unreleased: https://github.com/netorcai/hexabomb/compare/v0.1.0...master

.. _Keep a Changelog: http://keepachangelog.com/en/1.0.0
.. _Semantic versioning: http://semver.org/spec/v2.0.0.html
.. _netorcai metaprotocol: https://github.com/netorcai/netorcai
