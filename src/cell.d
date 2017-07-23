import core.exception : AssertError;
import std.exception : assertThrown;

struct Cell
{
    private
    {
        uint _color = 0;
        bool _containsPlayer = false;
        bool _containsBomb = false;
        bool _containsWall = false;
    }

    @property uint color() { return _color; }
    @property bool containsPlayer() { return _containsPlayer; }
    @property bool containsBomb() { return _containsBomb; }
    @property bool containsWall() { return _containsWall; }

    @property uint color(uint c) { return _color = c; }
    @property bool containsPlayer(bool c) { return _containsPlayer = c; }
    @property bool containsBomb(bool c) { return _containsBomb = c; }
    @property bool containsWall(bool c) { return _containsWall = c; }

    invariant
    {
        assert(_containsWall + (_containsPlayer || _containsBomb) <= 1,
               "Invalid cell: Cannot contain a wall and something else.");
    }

    unittest // Properties
    {
        Cell c;
        assert(c.color == 0);
        assert(c.containsPlayer == false);
        assert(c.containsBomb == false);
        assert(c.containsWall == false);

        c.color = 10;
        assert(c.color == 10);

        c.containsPlayer = true;
        assert(c.containsPlayer == true);

        c.containsBomb = true;
        assert(c.containsBomb = true);

        c = Cell();
        c.containsWall = true;
        assert(c.containsWall == true);
    }

    unittest // Checks cell types validity
    {
        Cell empty, full, wall, c;
        full.containsPlayer = true;
        full.containsBomb = true;
        wall.containsWall = true;

        // Players and bombs can be added in any order on the same cell
        c = empty;
        c.containsPlayer = true;
        c.containsBomb = true;

        c = empty;
        c.containsBomb = true;
        c.containsPlayer = true;

        // Player and bombs can leave the cell in any order
        c = full;
        c.containsPlayer = false;
        c.containsBomb = false;

        c = full;
        c.containsBomb = false;
        c.containsPlayer = false;

        // No bombs nor players on walls!
        c = wall;
        assertThrown!AssertError(c.containsPlayer = true);

        c = wall;
        assertThrown!AssertError(c.containsBomb = true);
    }
}