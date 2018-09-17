Game description
================

Introduction. TODO

Objective
---------
TODO

Actions
-------
TODO

Board
-----

The game board is an hexagonal grid composed of cells.

TODO: insert an example game board.

A cell can have up to 6 neighbors (three axes, two directions per axis).
Each cell is identified by its axial coordinates :math:`(q,r)`.
This coordinate system makes sure that different cells have different coordinates.
Furthermore, going into a direction always results in the same coordinate transformations.

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

Cell
----
TODO

Score
-----
At the end of each turn, the score of each player is increased by the number of
cells of the player's color.
As an example, consider the following 5-cell board on which 2 players (Blue and Green) play.
At the beginning, Blue and Green control the same number of cells and have the same score.

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

Turn
----
TODO
