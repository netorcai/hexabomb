import std.stdio;
import std.format;

struct Position
{
    int x=0;
    int y=0;

    string toString() const pure @safe
    {
        return format!"{x=%d,y=%d}"(x,y);
    }
}

// Basic Position tests
pure nothrow @nogc @safe unittest
{
    Position p, p2;
    assert(p.x == 0);
    assert(p.y == 0);

    assert(p == p2);

    p.x = 3;
    p.y = 4;
    assert(p.x == 3);
    assert(p.y == 4);

    assert(p != p2);
    assert(p == Position(3,4));

    p2 = Position(3,4);
    assert(p == p2);
}

struct Character
{
    immutable uint color;
    bool alive = true;
}

struct Cell
{
    uint color = 0;
    bool containsPlayer = false;
    bool containsBomb = false;
    bool containsWall = false;

    invariant
    {
        assert(containsWall + (containsPlayer || containsBomb) <= 1,
               "Invalid cell: Cannot contain a wall and something else.");
    }
}

class Board
{
    private
    {
        Cell[Position] cells;
    }

    inout(Cell) * cellAt(in Position pos) inout
    {
        auto cell = (pos in cells);
        assert(cell !is null, "No cell at pos=" ~ pos.toString());

        return cell;
    }

    bool cellExists(in Position pos) immutable pure nothrow @nogc
    {
        return (pos in cells) is null;
    }
}
