Changelog
=========

All notable changes to this project will be documented in this file.
The format is based on `Keep a Changelog`_.
hexabomb adheres to `Semantic Versioning`_ and its public API includes the
following.

- hexabomb's command-line interface.
- hexabomb's game-dependent protocol (that uses the `netorcai metaprotocol`_).
- hexabomb's game rules and their implementation.

........................................................................................................................

Unreleased
----------

- `Commits since v1.1.0 <https://github.com/netorcai/hexabomb/compare/v1.1.0...master>`_

........................................................................................................................

v1.1.0
------

- Release date: 2019-02-24
- `Commits since v1.0.0 <https://github.com/netorcai/hexabomb/compare/v1.0.0...v1.1.0>`_

Added
~~~~~

- New sudden death game mode, in which the objective of each player is to survive as long as possible.
  To enable this game mode, run a netorcai game with 1 special player.
- Cells that just exploded are now in the game state sent to clients each turn.

........................................................................................................................

v1.0.0
------

- Release date: 2019-01-19
- `Commits since v0.1.0 <https://github.com/netorcai/hexabomb/compare/v0.1.0...v1.0.0>`_

Changed game rules
~~~~~~~~~~~~~~~~~~

- Characters can no longer be revived right away after being killed.
- Characters can no longer be revived on a target cell —
  this is now only possible on the cell where they died.
- Characters now have a bomb count (0, 1 or 2). Dropping a bomb costs one bomb.
  The bomb count of all characters is increased by 1 every 10 turns (cannot exceed 2).
  The bomb count initial value is 1.
- Walls have been removed, as they were equivalent to an absence of cell.
- The game state format is now the same in ``DO_INIT_ACK`` and ``DO_TURN_ACK``.

Fixed
~~~~~

- Only one character was allowed per player.

........................................................................................................................

v0.1.0
------

- Initial release.
- Release date: 2018-10-30.

.. _Keep a Changelog: http://keepachangelog.com/en/1.0.0
.. _Semantic versioning: http://semver.org/spec/v2.0.0.html
.. _netorcai metaprotocol: https://github.com/netorcai/netorcai
