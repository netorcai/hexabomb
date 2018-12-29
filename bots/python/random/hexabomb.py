#!/usr/bin/env python3
from collections import namedtuple

class Coordinates:
    def __init__(self, dictionary, field_q='q', field_r='r'):
        self.q = dictionary[field_q]
        self.r = dictionary[field_r]

class Character:
    def __init__(self, dictionary):
        self.id = dictionary["id"]
        self.coord = Coordinates(dictionary)
        self.color = dictionary["color"]
        self.is_alive = dictionary["alive"]
        self.revive_delay = dictionary["revive_delay"]

class Bomb:
    def __init__(self, dictionary):
        self.coord = Coordinates(dictionary)
        self.color = dictionary["color"]
        self.range = dictionary["range"]
        self.delay = dictionary["delay"]

class Cell:
    def __init__(self, dictionary):
        self.coord = Coordinates(dictionary)
        self.color = dictionary["color"]

class GameState:
    def __init__(self, dictionary):
        self.cells = dict()
        self.characters = list()
        self.bombs = list()
        self.score = dictionary["score"]
        self.cell_count = dictionary["cell_count"]

        for raw_cell in dictionary["cells"]:
            cell = Cell(raw_cell)
            self.cells[cell.coord] = cell

        for raw_character in dictionary["characters"]:
            character = Character(raw_character)
            self.characters.append(character)

        for raw_bomb in dictionary["bombs"]:
            bomb = Bomb(raw_bomb)
            self.bombs.append(bomb)

