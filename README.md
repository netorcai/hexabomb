hexabomb
========
Artificial Intelligence Challenge - D Game Server

[![Build Status](https://travis-ci.org/mpoquet/hexabomb.svg?branch=master)](https://travis-ci.org/mpoquet/hexabomb)
[![Coverage Status](https://coveralls.io/repos/github/mpoquet/hexabomb/badge.svg?branch=master)](https://coveralls.io/github/mpoquet/hexabomb?branch=master)

Introduction
===========

hexabomb is a network multi-agent (multi-player) game, intended to be played by bots.
The game is strongly inspired by Bomberman and Splatoon, with hexagons ;).

Each agent controls characters that move on a board.
A color is associated to each agent.
The goal of each agent is to have the largest numbers of cell of its color in the board.

For this purpose, the characters may drop bombs that color surrounding cells when they explode.
Additionally, the characters colors the cells they go through.

Game board
==========

The game board is an hexagonal grid composed of cells.
A cell can have up to 6 neighbors (three axes, two directions per axis).

![Axial coordinate system][axial coordinate system]

Each cell is identified by its axial coordinates (q,r).
The axial coordinate system makes sure that two different cells have different coordinates.
This system is quite handy since going in any direction always results in the same coordinate transformation.

Let (q,r) be a cell from the board.
Let (a,b) be a neighboring cell of (q,r).
The (a,b) coordinates can be computed from (q,r) by adding (dx,dy) to it,
where (dx,dy) depends on the direction from (q,r) to (a,b):

| Direction |          Meaning         | (dx,dy) |
|:---------:|:------------------------:|:-------:|
| x+        | towards right            | (+1,0)  |
| y+        | towards up and right     | (+1,-1) |
| z+        | towards up and left      | (0,-1)  |
| x-        | towards left             | (-1,0)  |
| y-        | towards bottom and left  | (-1,+1) |
| z-        | towards bottom and right | (0,+1)  |

[axial coordinate system]: doc/img/hexagon.png "Axial coordinate system"
