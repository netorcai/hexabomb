import core.exception : AssertError;
import std.exception : assertThrown;

import std.format;
import std.stdio;

import cell;

struct Position
{
    int x=0;
    int y=0;

    pure nothrow @nogc @safe unittest // Basic manipulations
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

    string toString() const pure @safe
    {
        return format!"{x=%d,y=%d}"(x,y);
    }
    pure @safe unittest
    {
        Position p = Position(-51, 37);
        assert(p.toString == "{x=-51,y=37}");
    }

    Position opBinary(string op)(Position rhs) const @safe
    {
        static if (op == "+" || op == "-")
            return Position(mixin("x "~op~" rhs.x"), mixin("y "~op~" rhs.y"));
        else static assert(0, "Operator "~op~" not implemented");
    }
    unittest
    {
        assert(Position(0,0) + Position(0,0) == Position(0,0));
        assert(Position(5,7) + Position(0,0) == Position(5,7));
        assert(Position(7,5) + Position(0,0) == Position(7,5));
        assert(Position(5,7) + Position(2,1) == Position(7,8));

        assert(Position(0,0) - Position(0,0) == Position(0,0));
        assert(Position(5,7) - Position(0,0) == Position(5,7));
        assert(Position(7,5) - Position(0,0) == Position(7,5));
        assert(Position(5,7) - Position(2,1) == Position(3,6));
    }
}

enum : Position
{
    X_PLUS = Position(+1,  0),
    Y_PLUS = Position(+1, -1),
    Z_PLUS = Position( 0, -1),
    X_MINUS = Position(-1,  0),
    Y_MINUS = Position(-1, +1),
    Z_MINUS = Position( 0, +1)
}

immutable Position[6] offsets = [X_PLUS, Y_PLUS, Z_PLUS,
                                 X_MINUS, Y_MINUS, Z_MINUS];

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



    void addCell(in Position pos, in Cell cell) @safe
    in
    {
        assert(!cellExists(pos),
               "There is already a cell at pos=" ~ pos.toString);
    }
    body
    {
        _cells[pos] = cell;
    }


    inout(Cell*) cellAt(in Position pos) inout pure @safe
    {
        auto cell = (pos in _cells);
        assert(cell !is null, "No cell at pos=" ~ pos.toString);

        return cell;
    }
    inout(Cell*) cellAtOrNull(in Position pos) inout pure @safe
    {
        return (pos in _cells);
    }


    bool cellExists(in Position pos) const pure nothrow @nogc @safe
    {
        return (pos in _cells) !is null;
    }
    unittest // Cell existence
    {
        Board b = new Board;
        assert(b.cellExists(Position(0,0)) == false);
        assertThrown!AssertError(b.cellAt(Position(0,0)));
        assert(b.cellAtOrNull(Position(0,0)) is null);

        b.addCell(Position(0,0), Cell());
        assert(b.cellExists(Position(0,0)) == true);
        assert(b.cellAt(Position(0,0)) !is null);
        assert(b.cellAtOrNull(Position(0,0)) == b.cellAt(Position(0,0)));

        // Multiple addition
        assertThrown!AssertError(b.addCell(Position(0,0), Cell()));
    }


    Position[] neighborsOf(in Position pos) pure @safe
    in
    {
        assert(cellExists(pos), "No cell at pos=" ~ pos.toString);
    }
    out (result)
    {
        assert(result.length <= 6);
    }
    body
    {
        Position[] neighbors;

        foreach (offset; offsets)
        {
            auto p = pos + offset;

            if (cellExists(p))
            {
                neighbors ~= p;
            }
        }

        return neighbors;
    }
    unittest
    {
        Board b = new Board;
        assertThrown!AssertError(b.neighborsOf(Position(0,0)));

        b.addCell(Position(0,0), Cell());
        assert(b.neighborsOf(Position(0,0)) == []);

        b.addCell(Position(1,0), Cell());
        assert(b.neighborsOf(Position(0,0)) == [Position(1,0)]);
        assert(b.neighborsOf(Position(1,0)) == [Position(0,0)]);

        b.addCell(Position(0,1), Cell());
        assert(b.neighborsOf(Position(0,0)) == [Position(1,0),
                                                Position(0,1)]);
        assert(b.neighborsOf(Position(1,0)) == [Position(0,0),
                                                Position(0,1)]);
        assert(b.neighborsOf(Position(0,1)) == [Position(1,0),
                                                Position(0,0)]);

        b.addCell(Position(2,-1), Cell());
        assert(b.neighborsOf(Position(0,0)) == [Position(1,0),
                                                Position(0,1)]);
        assert(b.neighborsOf(Position(1,0)) == [Position(2,-1),
                                                Position(0,0),
                                                Position(0,1)]);
        assert(b.neighborsOf(Position(0,1)) == [Position(1,0),
                                                Position(0,0)]);
        assert(b.neighborsOf(Position(2,-1)) == [Position(1,0)]);
    }
}
