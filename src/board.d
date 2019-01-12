import core.exception : AssertError;
import std.algorithm : canFind, sort;
import std.container : DList;
import std.conv;
import std.exception;
import std.format;
import std.json;
import std.stdio;
import std.typecons;

import netorcai.json_util;

import bomb;
import cell;

struct Position
{
    int q=0;
    int r=0;

    pure nothrow @nogc @safe unittest // Basic manipulations
    {
        Position p, p2;
        assert(p.q == 0);
        assert(p.r == 0);

        assert(p == p2);

        p.q = 3;
        p.r = 4;
        assert(p.q == 3);
        assert(p.r == 4);

        assert(p != p2);
        assert(p == Position(3,4));

        p2 = Position(3,4);
        assert(p == p2);
    }

    string toString() const pure @safe
    {
        return format!"{q=%d,r=%d}"(q,r);
    }
    pure @safe unittest
    {
        Position p = Position(-51, 37);
        assert(p.toString == "{q=-51,r=37}");
    }

    Position opBinary(string op)(Position rhs) const @safe
    {
        static if (op == "+" || op == "-")
            return Position(mixin("q " ~ op ~ " rhs.q"),
                            mixin("r " ~ op ~ " rhs.r"));
        else static assert(0, "Operator " ~ op ~ " not implemented");
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

    int opCmp(const Position oth) const
    {
        if (q == oth.q)
            return r - oth.r;
        else
            return q - oth.q;
    }
    unittest
    {
        assert(Position(0,0) == Position(0,0));
        assert(Position(0,1) != Position(1,0));
        assert(Position(4,2) == Position(4,2));
        assert(Position(0,1) != Position(0,0));
        assert(Position(0,0) != Position(0,1));

        assert(Position(0,0) <= Position(0,0));
        assert(Position(0,0) >= Position(0,0));

        assert(Position(0,1) > Position(0,0));
        assert(Position(1,0) > Position(0,0));
        assert(Position(1,0) > Position(0,1));

        assert(Position(0,0) < Position(0,1));
        assert(Position(0,0) < Position(1,0));
        assert(Position(0,1) < Position(1,0));
    }
}

enum Direction : Position
{
    X_PLUS = Position(+1,  0),
    Y_PLUS = Position(+1, -1),
    Z_PLUS = Position( 0, -1),
    X_MINUS = Position(-1,  0),
    Y_MINUS = Position(-1, +1),
    Z_MINUS = Position( 0, +1)
}

immutable Position[6] offsets = [
    Direction.X_PLUS, Direction.Y_PLUS, Direction.Z_PLUS,
    Direction.X_MINUS, Direction.Y_MINUS, Direction.Z_MINUS];

class Board
{
    private
    {
        Cell[Position] _cells;
        Position[][Position] _neighbors;
    }

    this()
    {}

    this(in JSONValue array)
    in
    {
        assert(array.type == JSON_TYPE.ARRAY,
            "JSON value " ~ array.toString ~ " is not an array");
    }
    body
    {
        foreach(i, o; array.array)
        {
            enforce(o.type == JSON_TYPE.OBJECT,
                "Element " ~ to!string(i) ~ " (" ~ o.toString ~ ") is not an object");

            Position p;
            p.q = o["q"].getInt;
            p.r = o["r"].getInt;

            addCell(p, Cell());
        }

        updateNeighborsCache;
    }

    @property Position[] neighbors(in Position pos) pure @safe
    in
    {
        assert(cellExists(pos), "No cell at pos=" ~ pos.toString);
    }
    body
    {
        auto neighbors = (pos in _neighbors);
        if (neighbors !is null)
            return *neighbors;
        else
        {
            updateNeighborsCache(pos);
            return _neighbors[pos];
        }
    }
    unittest
    {
        Board b = new Board;
        b.addCell(Position(0,0), Cell());
        assert((Position(0,0) in b._neighbors) is null);
        assert(b.neighbors(Position(0,0)) == b.computeNeighbors(Position(0,0)));
        assert((Position(0,0) in b._neighbors) !is null);

        b.addCell(Position(0,1), Cell());
        assert(b._neighbors[Position(0,0)] != b.computeNeighbors(Position(0,0)));
        assert(b.neighbors(Position(0,0)) != b.computeNeighbors(Position(0,0)));
        b.updateNeighborsCache(Position(0,0));
        assert(b.neighbors(Position(0,0)) == b.computeNeighbors(Position(0,0)));
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

    void removeCell(in Position pos) @safe
    in
    {
        assert(cellExists(pos), "There is no cell at pos=" ~ pos.toString);
    }
    body
    {
        _cells.remove(pos);
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


    Position[] computeNeighbors(in Position pos) pure @safe
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
        assertThrown!AssertError(b.computeNeighbors(Position(0,0)));

        b.addCell(Position(0,0), Cell());
        assert(b.computeNeighbors(Position(0,0)) == []);

        b.addCell(Position(1,0), Cell());
        assert(b.computeNeighbors(Position(0,0)) == [Position(1,0)]);
        assert(b.computeNeighbors(Position(1,0)) == [Position(0,0)]);

        b.addCell(Position(0,1), Cell());
        assert(b.computeNeighbors(Position(0,0)) == [Position(1,0),
                                                Position(0,1)]);
        assert(b.computeNeighbors(Position(1,0)) == [Position(0,0),
                                                Position(0,1)]);
        assert(b.computeNeighbors(Position(0,1)) == [Position(1,0),
                                                Position(0,0)]);

        b.addCell(Position(2,-1), Cell());
        assert(b.computeNeighbors(Position(0,0)) == [Position(1,0),
                                                Position(0,1)]);
        assert(b.computeNeighbors(Position(1,0)) == [Position(2,-1),
                                                Position(0,0),
                                                Position(0,1)]);
        assert(b.computeNeighbors(Position(0,1)) == [Position(1,0),
                                                Position(0,0)]);
        assert(b.computeNeighbors(Position(2,-1)) == [Position(1,0)]);
    }


    void updateNeighborsCache(in Position pos) pure @safe
    in
    {
        assert(cellExists(pos), "No cell at pos=" ~ pos.toString);
    }
    out
    {
        assert((pos in _neighbors) !is null,
               "No cached neighbors at pos=" ~ pos.toString);
    }
    body
    {
        _neighbors[pos] = computeNeighbors(pos);
    }
    unittest
    {
        Board b = new Board;

        b.addCell(Position(0,0), Cell());
        assert((Position(0,0) in b._neighbors) is null);
        b.updateNeighborsCache(Position(0,0));
        assert(b._neighbors[Position(0,0)] == b.computeNeighbors(Position(0,0)));

        b.addCell(Position(1,0), Cell());
        b.updateNeighborsCache(Position(1,0));
        assert(b._neighbors[Position(1,0)] == b.computeNeighbors(Position(1,0)));
        assert(b._neighbors[Position(0,0)] != b.computeNeighbors(Position(0,0)));
        b.updateNeighborsCache(Position(0,0));
        assert(b._neighbors[Position(0,0)] == b.computeNeighbors(Position(0,0)));
    }

    void updateNeighborsCache() pure
    out
    {
        foreach (cellPosition; _cells.keys)
        {
            assert((cellPosition in _neighbors) !is null,
                   "Neighbors of cell at " ~ cellPosition.toString ~
                   "have not been computed");
        }
    }
    body
    {
        foreach (cellPosition; _cells.keys)
        {
            _neighbors[cellPosition] = computeNeighbors(cellPosition);
        }
    }

    int[Position] computeExplosionRange(in Bomb bomb)
    in
    {
        assert(cellExists(bomb.position), "Bomb is not in the board. " ~
                                          "pos=" ~ bomb.position.toString);
    }
    out (result)
    {
        assert(result.length <= bomb.range * 6 + 1);
    }
    body
    {
        int[Position] explodingCells = [bomb.position: 0];

        // Straight lines in all directions
        foreach (offset; offsets)
        {
            Position pos = bomb.position;
            foreach(dist ; 1..bomb.range+1)
            {
                pos = pos + offset;
                if (cellExists(pos))
                    explodingCells[pos] = dist;
                else
                    break;
            }
        }
        return explodingCells;
    }
    unittest
    {
        Board b = generateEmptyBoard;

        void wrapperAssertEquals(in int[Position] a, in int[Position] b,
                                 in string prefix)
        {
            assert(a == b,
                format!"Array mismatch in test %s.\na=%s.\nb=%s."(prefix, a, b));
        }

        Bomb bomb;
        bomb.position = Position(0,0);

        // Distance 0
        bomb.range = 0;
        assert(b.computeExplosionRange(bomb) == [Position(0,0): 0]);

        // Distance 1
        bomb.range = 1;
        wrapperAssertEquals(b.computeExplosionRange(bomb),
                            [Position( 0, 0) : 0,
                             Position( 1, 0) : 1,
                             Position( 1,-1) : 1,
                             Position( 0,-1) : 1,
                             Position(-1, 0) : 1,
                             Position(-1, 1) : 1,
                             Position( 0, 1) : 1],
                            "Range 1");

        // Distance 2
        bomb.range = 2;
        wrapperAssertEquals(b.computeExplosionRange(bomb),
                            [Position( 0, 0) : 0,
                             Position( 1, 0) : 1, Position( 2, 0) : 2,
                             Position( 1,-1) : 1, Position( 2,-2) : 2,
                             Position( 0,-1) : 1, Position( 0,-2) : 2,
                             Position(-1, 0) : 1, Position(-2, 0) : 2,
                             Position(-1, 1) : 1, Position(-2, 2) : 2,
                             Position( 0, 1) : 1, Position( 0, 2) : 2],
                            "Range 2");

        // Distance 3
        bomb.range = 3;
        wrapperAssertEquals(b.computeExplosionRange(bomb),
                            [Position( 0, 0) : 0,
                             Position( 1, 0) : 1, Position( 2, 0) : 2, Position( 3, 0) : 3,
                             Position( 1,-1) : 1, Position( 2,-2) : 2, Position( 3,-3) : 3,
                             Position( 0,-1) : 1, Position( 0,-2) : 2, Position( 0,-3) : 3,
                             Position(-1, 0) : 1, Position(-2, 0) : 2, Position(-3, 0) : 3,
                             Position(-1, 1) : 1, Position(-2, 2) : 2, Position(-3, 3) : 3,
                             Position( 0, 1) : 1, Position( 0, 2) : 2, Position( 0, 3) : 3],
                            "Range 3");

        // Distance 3, 1 hole.
        b.removeCell(Position( 1, 0));
        b.updateNeighborsCache;

        bomb.range = 3;
        wrapperAssertEquals(b.computeExplosionRange(bomb),
                            [Position( 0, 0) : 0,
                             Position( 1,-1) : 1, Position( 2,-2) : 2, Position( 3,-3) : 3,
                             Position( 0,-1) : 1, Position( 0,-2) : 2, Position( 0,-3) : 3,
                             Position(-1, 0) : 1, Position(-2, 0) : 2, Position(-3, 0) : 3,
                             Position(-1, 1) : 1, Position(-2, 2) : 2, Position(-3, 3) : 3,
                             Position( 0, 1) : 1, Position( 0, 2) : 2, Position( 0, 3) : 3],
                            "Range 3, 1 hole");
    }

    override bool opEquals(const Object o) @safe @nogc pure const
    {
        auto b = cast(const Board) o;
        return (this._cells == b._cells) && (this._neighbors == b._neighbors);
    }
    unittest
    {
        Board b1, b2;
        assert(b1 == b2);

        b1 = generateEmptyBoard;
        b2 = generateEmptyBoard;
        assert(b1 == b2);

        b1.addCell(Position(4, 0), Cell());
        assert(b1 != b2);
        b2.addCell(Position(4, 0), Cell());
        assert(b1 == b2);

        b1.updateNeighborsCache;
        assert(b1 != b2);
        b2.updateNeighborsCache;
        assert(b1 == b2);

        b1.updateNeighborsCache;
        assert(b1 == b2);
    }

    override string toString()
    {
        // Explicitly sort the data for deterministic prints
        import std.algorithm;
        import std.array;

        return format!"{cells:[%s], neighbors:[%s]}"(
            _cells.keys.sort.map!(pos => format!"%s:%s"(pos,_cells[pos])).join(", "),
            _neighbors.keys.sort.map!(pos => format!"%s:%s"(pos, _neighbors[pos].sort)).join(", ")
        );
    }
    unittest
    {
        auto b = new Board;
        assert(b.toString == "{cells:[], neighbors:[]}");

        b._cells = [
            Position(0,0): Cell(1, false, true),
            Position(0,1): Cell(2, true, false)];
        assert(b.toString == "{cells:[{q=0,r=0}:{color=1,bomb}, {q=0,r=1}:{color=2,char}], neighbors:[]}");

        b.updateNeighborsCache;
        assert(b.toString == "{cells:[{q=0,r=0}:{color=1,bomb}, {q=0,r=1}:{color=2,char}], neighbors:[{q=0,r=0}:[{q=0,r=1}], {q=0,r=1}:[{q=0,r=0}]]}");
    }

    JSONValue toJSON() const
    out(r)
    {
        assert(r.type == JSON_TYPE.ARRAY);
    }
    body
    {
        JSONValue v = `[]`.parseJSON;

        alias PosCell = Tuple!(Position, "position", Cell, "cell");
        PosCell[] tuples;
        foreach(pos, cell; _cells)
            tuples ~= PosCell(pos, cell);

        foreach(t ; tuples.sort!"a.position < b.position")
        {
            JSONValue cellValue = `{}`.parseJSON;
            cellValue.object["q"] = t.position.q;
            cellValue.object["r"] = t.position.r;
            cellValue.object["color"] = t.cell.color;

            v.array ~= cellValue;
        }

        return v;
    }
    unittest
    {
        JSONValue boardDescription = `[
          {"q": 0, "r":-3, "color": 0},
          {"q": 1, "r":-3, "color": 0},
          {"q": 2, "r":-5, "color": 0},
          {"q": 2, "r":-3, "color": 0},
          {"q": 3, "r":-3, "color": 0}
        ]`.parseJSON;
        Board b = new Board(boardDescription);
        assert(b.toJSON.toString == boardDescription.toString);
    }

    uint[uint] cellCountPerColor()
    {
        import std.algorithm;

        uint[uint] cellCount;
        _cells.values.each!(c => cellCount[c.color] += 1);

        return cellCount;
    }
}

Board generateEmptyBoard()
{
    Board b = new Board;

    b.addCell(Position(0 ,-3), Cell());
    b.addCell(Position(1 ,-3), Cell());
    b.addCell(Position(2 ,-3), Cell());
    b.addCell(Position(3 ,-3), Cell());

    b.addCell(Position(-1,-2), Cell());
    b.addCell(Position(0 ,-2), Cell());
    b.addCell(Position(1 ,-2), Cell());
    b.addCell(Position(2 ,-2), Cell());
    b.addCell(Position(3 ,-2), Cell());

    b.addCell(Position(-2,-1), Cell());
    b.addCell(Position(-1,-1), Cell());
    b.addCell(Position(0 ,-1), Cell());
    b.addCell(Position(1 ,-1), Cell());
    b.addCell(Position(2 ,-1), Cell());
    b.addCell(Position(3 ,-1), Cell());

    b.addCell(Position(-3, 0), Cell());
    b.addCell(Position(-2, 0), Cell());
    b.addCell(Position(-1, 0), Cell());
    b.addCell(Position(0 , 0), Cell());
    b.addCell(Position(1 , 0), Cell());
    b.addCell(Position(2 , 0), Cell());
    b.addCell(Position(3 , 0), Cell());

    b.addCell(Position(-3, 1), Cell());
    b.addCell(Position(-2, 1), Cell());
    b.addCell(Position(-1, 1), Cell());
    b.addCell(Position(0 , 1), Cell());
    b.addCell(Position(1 , 1), Cell());
    b.addCell(Position(2 , 1), Cell());

    b.addCell(Position(-3, 2), Cell());
    b.addCell(Position(-2, 2), Cell());
    b.addCell(Position(-1, 2), Cell());
    b.addCell(Position( 0, 2), Cell());
    b.addCell(Position( 1, 2), Cell());

    b.addCell(Position(-3, 3), Cell());
    b.addCell(Position(-2, 3), Cell());
    b.addCell(Position(-1, 3), Cell());
    b.addCell(Position( 0, 3), Cell());

    b.updateNeighborsCache;

    return b;
}

unittest // Construction from JSON
{
    Board b1 = new Board(`[
        {"q": 0 , "r":-3},
        {"q": 1 , "r":-3},
        {"q": 2 , "r":-3},
        {"q": 3 , "r":-3},

        {"q": -1, "r":-2},
        {"q": 0 , "r":-2},
        {"q": 1 , "r":-2},
        {"q": 2 , "r":-2},
        {"q": 3 , "r":-2},

        {"q": -2, "r":-1},
        {"q": -1, "r":-1},
        {"q": 0 , "r":-1},
        {"q": 1 , "r":-1},
        {"q": 2 , "r":-1},
        {"q": 3 , "r":-1},

        {"q": -3, "r": 0},
        {"q": -2, "r": 0},
        {"q": -1, "r": 0},
        {"q": 0 , "r": 0},
        {"q": 1 , "r": 0},
        {"q": 2 , "r": 0},
        {"q": 3 , "r": 0},

        {"q": -3, "r": 1},
        {"q": -2, "r": 1},
        {"q": -1, "r": 1},
        {"q": 0 , "r": 1},
        {"q": 1 , "r": 1},
        {"q": 2 , "r": 1},

        {"q": -3, "r": 2},
        {"q": -2, "r": 2},
        {"q": -1, "r": 2},
        {"q": 1 , "r": 2},

        {"q": -3, "r": 3},
        {"q": -2, "r": 3},
        {"q": -1, "r": 3},
        {"q": 0 , "r": 3}
    ]`.parseJSON);

    Board b2 = generateEmptyBoard;
    assert(b1 != b2);

    b1.addCell(Position(0,2), Cell());
    b1.updateNeighborsCache;
    assert(b1 == b2);

    string s = `[1]`;
    assertThrown(new Board(s.parseJSON));
    assert(collectExceptionMsg(new Board(s.parseJSON)) ==
            "Element 0 (1) is not an object");
}
