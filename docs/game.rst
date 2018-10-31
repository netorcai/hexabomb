Game description
================
hexabomb is a network multi-player (multi-agent) game, intended to be played by bots.
The game is strongly inspired by Bomberman and Splatoon, with hexagons.

Each player controls characters that move on a board.
A color is associated to each player.
The goal of each player is to have the largest numbers of cell of its color in the board.

For this purpose, the characters color the cells they go through.
Additionally, the characters may drop bombs that color surrounding cells when they explode.

Board
-----
The game board is an hexagonal grid composed of cells.

.. image:: img/board_example.png
   :scale: 100 %
   :alt: Board example

A cell can have up to 6 neighbors (three axes, two directions per axis).
Each cell is identified by its axial coordinates :math:`(q,r)`.
This coordinate system makes sure that different cells have different coordinates,
and that going into a given direction always results in the same coordinate transformations.

.. list-table:: Coordinates transformations from cell :math:`(q,r)` to its neighboring cells.
    :header-rows: 1

    * - Direction
      - Meaning
      - Destination cell
    * - :math:`x^+`
      - towards right
      - :math:`(q+1,r)`
    * - :math:`y^+`
      - towards up and right
      - :math:`(q+1,r-1)`
    * - :math:`z^+`
      - towards up and left
      - :math:`(q,r-1)`
    * - :math:`x^-`
      - towards left
      - :math:`(q-1,r)`
    * - :math:`y^-`
      - towards bottom and left
      - :math:`(q-1,r+1)`
    * - :math:`z^-`
      - towards bottom and right
      - :math:`(q,r+1)`

.. image:: img/offsets.png
   :scale: 100 %
   :alt: coordinates transformations

Cells
-----
Two types of cells exist on the board: **usual cells** and **walls**.

Usual cells can host characters and bombs, and have a color (that can be neutral).
Characters can move into usual cells if they are empty — i.e., if they do not host characters nor bombs.
Usual cells can be colored by a bomb if they are in the bomb's explosion range.

Contrary to usual cells, walls are obstacles without color.
Characters cannot move into walls.
Bombs cannot traverse walls.
Bomb explosions are completely stopped by walls.

.. image:: img/cell_types.png
   :scale: 100 %
   :alt: figuration of cell types

Turns and actions
-----------------
The game is turn based. All players can do actions on each turn.
All players should follow the following behaviour.

1. Wait for a new turn to start.
2. Receive a new turn (up-to-date board information) from the network.
3. Decide what to do.
4. Send the actions on the network. Start again (goto step 1).

On each turn each character can either move or drop a bomb.
The exhaustive list of what each character can do is the following.

- Do nothing.
- **move**: Move one cell towards one of the 6 directions.
- **bomb**: Drop a bomb in the character current cell.

hexabomb will apply the players' decisions in best effort.
In case of conflicts, the faster player is priority.

Objective and score
-------------------
At the end of the game, the player with the highest score wins the game.

The score of each player is the cumulated number of cells it controlled throughout the turns.
In other words, at the end of each turn, the score of each player is increased by the number of
cells of the player's color.

As an example, consider the following 5-cell board on which 2 players (Blue and Green) play.
At the beginning, Blue and Green control the same number of cells (1) and have the same score (1).

.. image:: img/score_turn0.png
   :scale: 100 %
   :alt: score turn 0

On first turn, Blue moves while Green does not.
This allows Blue to earn 2 points this turn, while Green only earns 1 point.

.. image:: img/score_turn1.png
   :scale: 100 %
   :alt: score turn 1

Green remains motionless in the next turns, while Blue controls more and more cells.
As a result, Blue's score increases way more than Green's.

.. image:: img/score_turn2.png
   :scale: 100 %
   :alt: score turn 2

.. image:: img/score_turn3.png
   :scale: 100 %
   :alt: score turn 3


Bombs
-----
Bombs can be dropped by characters on their current cell.
Bombs explode after a given **delay** and have a **range**.
Upon explosion, bombs color the cells of their explosion area with the color
of the player that dropped the bomb — killing any character and exploding any bomb present in the explosion area.

Bombs explode in straight lines in all 6 directions and cover up to *range*
cells in each direction. A line is stopped if it encounters a wall — or after *range* cells have been covered.

The animation below shows a simple game scenario involving a bomb.

1. On first turn, Green drops a bomb (delay=3, range=2) and moves away from it.
2. On second turn, Green moves away from the bomb explosion area.
3. On third turn, nothing happens.
4. During fourth turn, the bomb explodes as its delay reaches 0.
   The explosion area is highlighted in orange.
   At the end of the fourth turn, all the cells of the explosion range have been colored in green.
   Blue is killed in the process as it was in the explosion area.

.. image:: img/explosion_thin.gif
   :scale: 100 %
   :alt: figuration of a bomb lifecycle

Simultaneous explosions
~~~~~~~~~~~~~~~~~~~~~~~
Several bombs can explode at the same time.
This may happen when the delay of several bombs reaches 0 at the same time or in case of `Chain reaction`_.

Simultaneous explosions can lead to conflicts about the coloration of the cells — as some cells can be in the explosion area of several bombs of different colors.
This is how the color of an exploded cell is determined by hexabomb in case of simulateneous explosions.

1. If the cell is strictly closer to one bomb than the others, the cell is colored by the color of the closest bomb.
2. If all the bombs of the set of the closest bombs to that cell have the same color, the cell is colored by the color of the bombs.
3. Otherwise (e.g., if any two bombs of the set of the closest bombs to that cell have different colors), the cell color is turned to neutral.

Simultaneous explosions are figured just below.

.. image:: img/explosion_simultaneous.gif
   :scale: 100 %
   :alt: figuration of simultaneous explosions

Most of the exploded cells are closer to one bomb from the others and take the bomb's color.
The exploded cells that are at the same distance to multiple bombs are thickly bordered orange.

- Cell at :math:`(1,-3)` becomes green because the two closest bombs exploding it are green — bombs at :math:`(0,-3)` and :math:`(2,-3)`.
- Cell at :math:`(2,-1)` stays neutral because the two closest bombs exploding it are of different colors — bombs at :math:`(0,0)` and :math:`(2,-3)`.
- Cell at :math:`(-1,2)` stays neutral because the two closest bombs exploding it are of different colors — bombs at :math:`(0,0)` and :math:`(-3,3)`.
- Cell at :math:`(-2,1)` becomes neutral because the two closest bombs exploding it are of different colors — bombs at :math:`(0,0)` and :math:`(-3,3)`.

Chain reaction
~~~~~~~~~~~~~~
Without any external influence, a bomb explodes when its delay reaches 0.
A bomb can however explode before reaching a delay of 0 because of another bomb.
This happens when a bomb is in the explosion area of another bomb (and when
the other bomb explodes first). This can lead to a chain reaction where many
bombs can explode at the same time.

If a chain reaction involves bombs of different colors,
see `Simultaneous explosions`_ to understand how the cells of the explosion areas are colored.

.. image:: img/explosion_chain_reaction.gif
   :scale: 100 %
   :alt: figuration of explosions in chain reaction

.. _breadth-first search: https://en.wikipedia.org/wiki/Breadth-first_search
