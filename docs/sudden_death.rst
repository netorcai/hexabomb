Sudden death
============

Sudden death is hexabomb's secondary game mode.
It is based on the classical game mode described in :ref:`game_description`.

The main difference is the players' objective:
They must now survive as long as possible without any consideration about the
coloration of cells.

Game rules modifications
------------------------

- Character death is permanent: ``revive`` action is not allowed.
- The score of a player is the number of turns it survived,
  that is to say the maximum turn number when it still had alive characters.
- There is a special player (identified by :math:`playerID = 0`)
  that hunts and kills other players' characters.
  The characters of this special player respect modified rules.

  - Not affected by bomb explosions.
  - Can drop as many bombs as they desire.
  - Can drop bombs with delays and ranges in :math:`[2,100]`.

How to detect current game mode?
--------------------------------

This depends on the number of special players that is received in
the GAME_STARTS_ message.

- 0 special players means the game mode is classical (described in :ref:`game_description`).
- 1 special player means the game mode is sudden death.

What is the special player strategy?
------------------------------------

- Attack close enemies.
- Try to circle enemies.
- Block small paths with bombs that have a long delay.

The following video shows a sudden death game with
the special player (ghost characters) and random players (cat characters).

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/XYMzw-pYgkA" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
    </div>


.. _GAME_STARTS: https://netorcai.readthedocs.io/en/latest/metaprotocol.html#game-starts
