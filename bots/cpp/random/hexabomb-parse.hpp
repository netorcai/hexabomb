#pragma once

#include <vector>
#include <unordered_map>

#include <netorcai-client-cpp/message.hpp>

/// Axial coordinates.
struct Coordinates
{
    int q;
    int r;
};

/// Sets the Coordinates struct as hashable.
/// This makes Coordinates usable as key for std::unordered_map.
namespace std
{
    template <>
    struct hash<Coordinates>
    {
        std::size_t operator()(const Coordinates & coord) const
        {
            return std::hash<int>()(coord.q)
                ^ (std::hash<int>()(coord.r) << 1);
        }
    };
}

// Equality / comparison in lexicographical order.
bool operator==(const Coordinates & c1, const Coordinates & c2);
bool operator<(const Coordinates & c1, const Coordinates & c2);

/// Character information.
struct Character
{
    int id; //!< Character unique identifier. Immutable.
    Coordinates coord; //!< Current coordinates.
    int color; //!< Color. Immutable.
    bool isAlive; //!< Whether the character is currently alive.
    int reviveDelay; //!< Revive delay. -1 for alive characters. Decreases by 1 each turn for dead characters. Dead characters can be revived when reviveDelay=0.
};

// Bomb information.
struct Bomb
{
    Coordinates coord; //!< The bomb coordinates: The center of its explosion area. Immutable.
    int color; //!< The bomb color. Used to determine the color of the exploded cells. Immutable.
    int range; //!< The bomb range. Up to range cells in each direction can be colored by the bomb. Immutable.
    int delay; //!< Bomb delay. Decreases by 1 each turn. Explodes when delay=0.
};

// Cell information.
struct Cell
{
    Coordinates coord; //!< The cell coordinates. Immutable.
    int color; //!< The cell color. Mutable.
};

void parseGameState(const netorcai::json & gameState,
    std::unordered_map<Coordinates, Cell> & cells,
    std::vector<Character> & characters,
    std::vector<Bomb> & bombs,
    std::map<int, int> & score,
    std::map<int, int> & cellCount);
