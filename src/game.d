import board;
import bomb;

struct Character
{
    immutable uint id;
    immutable uint color;
    bool alive = true;
}

class Game
{
    private
    {
        Board _board;
        Bomb[] _bombs;
        Character[] _characters;
    }
}
