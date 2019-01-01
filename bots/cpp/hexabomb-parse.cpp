#include "hexabomb-parse.hpp"

bool operator==(const Coordinates & c1, const Coordinates & c2)
{
    return (c1.q == c2.q) && (c1.r == c2.r);
}

bool operator<(const Coordinates & c1, const Coordinates & c2)
{
    if (c1.q == c2.q)
        return c1.r < c2.r;
    return c1.q < c2.q;
}

static void parseCells(const netorcai::json & jsonCells, std::unordered_map<Coordinates, Cell> & cells)
{
    for (const auto & jsonCell : jsonCells)
    {
        Coordinates coord;
        coord.q = jsonCell["q"];
        coord.r = jsonCell["r"];
        cells[coord].color = jsonCell["color"];
    }
}

static void parseCharacters(const netorcai::json & jsonCharacters, std::vector<Character> & characters)
{
    characters.clear();

    for (const auto & jsonCharacter : jsonCharacters)
    {
        Coordinates coord;
        coord.q = jsonCharacter["q"];
        coord.r = jsonCharacter["r"];

        Character c;
        c.id = jsonCharacter["id"];
        c.coord = coord;
        c.color = jsonCharacter["color"];
        c.isAlive = jsonCharacter["alive"];
        c.reviveDelay = jsonCharacter["revive_delay"];

        characters.push_back(c);
    }
}

static void parseBombs(const netorcai::json & jsonBombs, std::vector<Bomb> & bombs)
{
    bombs.clear();

    for (const auto & jsonBomb : jsonBombs)
    {
        Coordinates coord;
        coord.q = jsonBomb["q"];
        coord.r = jsonBomb["r"];

        Bomb b;
        b.coord = coord;
        b.color = jsonBomb["color"];
        b.range = jsonBomb["range"];
        b.delay = jsonBomb["delay"];

        bombs.push_back(b);
    }
}

static void parsePlayerIntMap(const netorcai::json & jsonObject, std::map<int, int> & m)
{
    netorcai::json * mutObject = const_cast<netorcai::json*>(&jsonObject);
    for (netorcai::json::iterator it = mutObject->begin(); it != mutObject->end(); ++it)
    {
        const int player_id = std::stoi(it.key());
        m[player_id] = it.value();
    }
}

/**
 * @brief Parse a netorcai game state for the hexabomb game
 * @param[in] gameState The game state to parse (json object)
 * @param[in, out] cells The board cells. Their color is updated by this function.
 * @param[out] characters The characters on the board. Completely updated by this function.
 * @param[out] bombs The bombs on the board. Completely updated by this function.
 * @param[out] score The score or each player. Key is player_id, value is the associated score.
 * @param[out] cellCount The number of cells of each player. Key is player_id, value is the associated number of cells.
 */
void parseGameState(const netorcai::json & gameState,
    std::unordered_map<Coordinates, Cell> & cells,
    std::vector<Character> & characters,
    std::vector<Bomb> & bombs,
    std::map<int, int> & score,
    std::map<int, int> & cellCount)
{
    parseCells(gameState["cells"], cells);
    parseCharacters(gameState["characters"], characters);
    parseBombs(gameState["bombs"], bombs);
    parsePlayerIntMap(gameState["score"], score);
    parsePlayerIntMap(gameState["cell_count"], cellCount);
}

