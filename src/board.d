import core.exception : AssertError;
import std.algorithm : canFind, sort;
import std.container : DList;
import std.exception : assertThrown;
import std.format;
import std.stdio;
import std.typecons;

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

    int opCmp(ref const Position oth) const
    {
        if (q == oth.q)
            return r - oth.r;
        else
            return q - oth.q;
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
        Position[][Position] _neighbors;
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

    Position[] computeExplosionRange(in Bomb bomb)
    in
    {
        assert(cellExists(bomb.position), "Bomb is not in the board. " ~
                                          "pos=" ~ bomb.position.toString);
    }
    out (result)
    {
        final switch(bomb.type)
        {
            case BombType.LONG:
                assert(result.length <= bomb.range * 6 + 1);
                break;
            case BombType.COMPACT:
                int max_cells = 1;
                foreach (distance; 1..bomb.range+1)
                    max_cells += distance*6;
                assert(result.length <= max_cells);
                break;
        }
    }
    body
    {
        Position[] explodingCells = [bomb.position];

        final switch(bomb.type)
        {
            bool isCellExplodable(in Cell* cell)
            {
                return !cell.isWall;
            }

            case BombType.LONG:
                // Straight lines in all directions
                foreach (offset; offsets)
                {
                    Position pos = bomb.position;
                    foreach(_; 0..bomb.range)
                    {
                        pos = pos + offset;
                        if (cellExists(pos) && isCellExplodable(cellAt(pos)))
                            explodingCells ~= pos;
                        else
                            break;
                    }
                }
                break;
            case BombType.COMPACT:
                // All cells around the bomb before a given distance
                // BFS
                alias PosDist = Tuple!(Position, "position", int, "distance");

                auto queue = DList!PosDist(PosDist(bomb.position, 0));

                while(!queue.empty)
                {
                    PosDist cd = queue.front;
                    queue.removeFront;

                    foreach (neighbor; _neighbors[cd.position])
                    {
                        if (cellExists(neighbor) &&
                            !canFind(explodingCells, neighbor) &&
                            isCellExplodable(cellAt(neighbor)) &&
                            cd.distance < bomb.range)
                        {
                            queue.insertBack(PosDist(neighbor, cd.distance+1));
                            explodingCells ~= neighbor;
                        }
                    }
                }
        }
        return explodingCells;
    }
    unittest
    {
        Board b = generate_empty_board;

        void wrapperAssertEquals(in Position[] a, in Position[] b,
                                 in string prefix)
        {
            Position[] copyA, copyB;

            copyA.length = a.length;
            copyB.length = b.length;

            copyA[] = a[];
            copyB[] = b[];

            copyA.sort!("a < b");
            copyB.sort!("a < b");

            if (copyA != copyB)
            {
                writeln("Array mismatch in test " ~ prefix,
                        "\na=", copyA, "\nb=", copyB);
                assert(0);
            }
        }

        Bomb bomb;
        bomb.position = Position(0,0);

        // Distance 0
        bomb.type = BombType.LONG;
        bomb.range = 0;
        assert(b.computeExplosionRange(bomb) == [Position(0,0)]);

        bomb.type = BombType.COMPACT;
        bomb.range = 0;
        assert(b.computeExplosionRange(bomb) == [Position(0,0)]);

        // Distance 1
        bomb.type = BombType.LONG;
        bomb.range = 1;
        wrapperAssertEquals(b.computeExplosionRange(bomb),
                            [Position( 0, 0),
                             Position( 1, 0),
                             Position( 1,-1),
                             Position( 0,-1),
                             Position(-1, 0),
                             Position(-1, 1),
                             Position( 0, 1)],
                            "Long 1");

        bomb.type = BombType.COMPACT;
        bomb.range = 1;
        wrapperAssertEquals(b.computeExplosionRange(bomb),
                            [Position( 0, 0),
                             Position( 1, 0),
                             Position( 1,-1),
                             Position( 0,-1),
                             Position(-1, 0),
                             Position(-1, 1),
                             Position( 0, 1)],
                            "Compact 1");

        // Distance 2
        bomb.type = BombType.LONG;
        bomb.range = 2;
        wrapperAssertEquals(b.computeExplosionRange(bomb),
                            [Position( 0, 0),
                             Position( 1, 0), Position( 2, 0),
                             Position( 1,-1), Position( 2,-2),
                             Position( 0,-1), Position( 0,-2),
                             Position(-1, 0), Position(-2, 0),
                             Position(-1, 1), Position(-2, 2),
                             Position( 0, 1), Position( 0, 2)],
                            "Long 2");

        bomb.type = BombType.COMPACT;
        bomb.range = 2;
        wrapperAssertEquals(b.computeExplosionRange(bomb),
                            [Position( 0, 0),
                             Position( 1, 0), Position( 2, 0),
                             Position( 1,-1), Position( 2,-2),
                             Position( 0,-1), Position( 0,-2),
                             Position(-1, 0), Position(-2, 0),
                             Position(-1, 1), Position(-2, 2),
                             Position( 0, 1), Position( 0, 2),
                             Position( 2,-1),
                             Position( 1,-2),
                             Position(-1,-1),
                             Position(-2, 1),
                             Position(-1, 2),
                             Position( 1, 1)],
                            "Compact 2");

        // Distance 3
        bomb.type = BombType.LONG;
        bomb.range = 3;
        wrapperAssertEquals(b.computeExplosionRange(bomb),
                            [Position( 0, 0),
                             Position( 1, 0), Position( 2, 0), Position( 3, 0),
                             Position( 1,-1), Position( 2,-2), Position( 3,-3),
                             Position( 0,-1), Position( 0,-2), Position( 0,-3),
                             Position(-1, 0), Position(-2, 0), Position(-3, 0),
                             Position(-1, 1), Position(-2, 2), Position(-3, 3),
                             Position( 0, 1), Position( 0, 2), Position( 0, 3)],
                            "Long 3");

        bomb.type = BombType.COMPACT;
        bomb.range = 3;
        wrapperAssertEquals(b.computeExplosionRange(bomb),
                            b._cells.keys,
                            "Compact 3");

        // Distance 3, 1 wall.
        b.cellAt(Position( 1, 0)).addWall;

        bomb.type = BombType.LONG;
        bomb.range = 3;
        wrapperAssertEquals(b.computeExplosionRange(bomb),
                            [Position( 0, 0),
                             Position( 1,-1), Position( 2,-2), Position( 3,-3),
                             Position( 0,-1), Position( 0,-2), Position( 0,-3),
                             Position(-1, 0), Position(-2, 0), Position(-3, 0),
                             Position(-1, 1), Position(-2, 2), Position(-3, 3),
                             Position( 0, 1), Position( 0, 2), Position( 0, 3)],
                            "Long 3, 1 wall");

        bomb.type = BombType.COMPACT;
        bomb.range = 3;
        wrapperAssertEquals(b.computeExplosionRange(bomb) ~ [Position(1,0),
                                                             Position(3,0)],
                            b._cells.keys,
                            "Compact 3, 1 wall");
    }
}

Board generate_empty_board()
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
