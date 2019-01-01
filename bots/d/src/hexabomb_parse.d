import std.json;

import netorcai.json_util;

/// Axial coordinates.
struct Coordinates
{
    int q;
    int r;
};

/// Character information.
struct Character
{
    int id; /// Character unique identifier. Immutable.
    Coordinates coord; /// Current coordinates.
    int color; /// Color. Immutable.
    bool isAlive; /// Whether the character is currently alive.
    int reviveDelay; /// Revive delay. -1 for alive characters. Decreases by 1 each turn for dead characters. Dead characters can be revived when reviveDelay=0.
};

// Bomb information.
struct Bomb
{
    Coordinates coord; /// The bomb coordinates: The center of its explosion area. Immutable.
    int color; /// The bomb color. Used to determine the color of the exploded cells. Immutable.
    int range; /// The bomb range. Up to range cells in each direction can be colored by the bomb. Immutable.
    int delay; /// Bomb delay. Decreases by 1 each turn. Explodes when delay=0.
};

// Cell information.
struct Cell
{
    Coordinates coord; /// The cell coordinates. Immutable.
    int color; /// The cell color. Mutable.
};

/// Parse a netorcai game state for the hexabomb game.
void parseGameState(in JSONValue gameState,
    out Cell[Coordinates] cells,
    out Character[] characters,
    out Bomb[] bombs,
    out int[int] score,
    out int[int] cellCount)
{
    parseCells(gameState["cells"].array, cells);
    parseCharacters(gameState["characters"].array, characters);
    parseBombs(gameState["bombs"].array, bombs);
    parsePlayerIntAssociativeArray(gameState["score"], score);
    parsePlayerIntAssociativeArray(gameState["cell_count"], cellCount);
}

void parseCells(in JSONValue[] jsonCells, out Cell[Coordinates] cells)
{
    foreach (jsonCell; jsonCells)
    {
        Cell c;
        c.coord.q = jsonCell["q"].getInt;
        c.coord.r = jsonCell["r"].getInt;
        c.color = jsonCell["color"].getInt;

        cells[c.coord] = c;
    }
}

void parseCharacters(in JSONValue[] jsonCharacters, out Character[] characters)
{
    foreach (jsonCharacter; jsonCharacters)
    {
        Coordinates coord;
        coord.q = jsonCharacter["q"].getInt;
        coord.q = jsonCharacter["r"].getInt;

        Character c;
        c.id = jsonCharacter["id"].getInt;
        c.coord = coord;
        c.color = jsonCharacter["color"].getInt;
        c.isAlive = jsonCharacter["alive"].getBool;
        c.reviveDelay = jsonCharacter["revive_delay"].getInt;

        characters ~= c;
    }
}

void parseBombs(in JSONValue[] jsonBombs, out Bomb[] bombs)
{
    foreach (jsonBomb; jsonBombs)
    {
        Coordinates coord;
        coord.q = jsonBomb["q"].getInt;
        coord.q = jsonBomb["r"].getInt;

        Bomb b;
        b.coord = coord;
        b.color = jsonBomb["color"].getInt;
        b.range = jsonBomb["range"].getInt;
        b.delay = jsonBomb["delay"].getInt;

        bombs ~= b;
    }
}

void parsePlayerIntAssociativeArray(in JSONValue jsonObject, out int[int] m)
{
    import std.conv;
    foreach (key, value; jsonObject.object)
    {
        m[to!int(key)] = value.getInt;
    }
}
