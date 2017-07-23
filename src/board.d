import core.exception : AssertError;
import std.exception : assertThrown;

import std.format;
import std.stdio;

import cell;

struct Position
{
    int x=0;
    int y=0;

    string toString() const pure @safe
    {
        return format!"{x=%d,y=%d}"(x,y);
    }

    pure @safe unittest // toString
    {
        Position p = Position(-51, 37);
        assert(p.toString == "{x=-51,y=37}");
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

class Board
{
    private
    {
        Cell[Position] _cells;
    }

    void addCell(in Position pos, in Cell cell)
    in
    {
        assert(!cellExists(pos),
               "There is already a cell at pos=" ~ pos.toString);
    }
    body
    {
        _cells[pos] = cell;
    }

    inout(Cell) * cellAt(in Position pos) inout pure
    {
        auto cell = (pos in _cells);
        assert(cell !is null, "No cell at pos=" ~ pos.toString());

        return cell;
    }

    bool cellExists(in Position pos) const pure nothrow @nogc
    {
        return (pos in _cells) !is null;
    }

    unittest // Cell existence
    {
        Board b = new Board;
        assert(b.cellExists(Position(0,0)) == false);
        assertThrown!AssertError(b.cellAt(Position(0,0)));

        b.addCell(Position(0,0), Cell());
        assert(b.cellExists(Position(0,0)) == true);
        assert(b.cellAt(Position(0,0)) !is null);

        // Multiple addition
        assertThrown!AssertError(b.addCell(Position(0,0), Cell()));
    }
}
