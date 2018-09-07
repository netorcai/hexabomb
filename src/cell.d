import core.exception : AssertError;
import std.exception : assertThrown;

import std.format;

struct Cell
{
    // Member variables
    private
    {
        uint _color = 0;
        bool _hasCharacter = false;
        bool _hasBomb = false;
        bool _isWall = false;
    }

    // "Get" properties
    @property uint color() const pure @safe @nogc { return _color; }
    @property bool hasCharacter() const pure @safe @nogc { return _hasCharacter; }
    @property bool hasBomb() const pure @safe @nogc { return _hasBomb; }
    @property bool isWall() const pure @safe @nogc { return _isWall; }
    @property bool isTraversable() const pure @safe @nogc
    {
        return !_isWall && !_hasCharacter && !_hasBomb;
    }
    @property bool isExplodable() const pure @safe @nogc { return !_isWall; }


    // Character manipulations
    @property void addCharacter(uint color) pure @safe @nogc
    in
    {
        assert(!_isWall, "Trying to add a character on a wall...");
        assert(!_hasCharacter, "Trying to add a character on a character...");
        assert(!_hasBomb, "Trying to add a character on a bomb...");
    }
    out
    {
        assert(_hasCharacter);
        assert(_color == color);
    }
    body
    {
        _hasCharacter = true;
        _color = color;
    }

    @property void removeCharacter() pure @safe @nogc
    in
    {
        assert(_hasCharacter, "There is no character on this cell...");
    }
    out
    {
        assert(!_hasCharacter);
    }
    body
    {
        _hasCharacter = false;
    }


    // Bomb manipulation
    @property void addBomb() pure @safe @nogc
    in
    {
        assert(!_isWall, "Trying to add a bomb on a wall...");
        assert(!_hasBomb, "Trying to add a bomb on a bomb...");
    }
    out
    {
        assert(_hasBomb);
    }
    body
    {
        _hasBomb = true;
    }

    @property void removeBomb() pure @safe @nogc
    in
    {
        assert(_hasBomb, "There is no bomb on this cell...");
    }
    out
    {
        assert(!_hasBomb);
    }
    body
    {
        _hasBomb = false;
    }


    // Wall manipulation
    @property void addWall() pure @safe @nogc
    in
    {
        assert(!_hasCharacter, "Trying to add a wall on a character...");
        assert(!_hasBomb, "Trying to add a wall on a bomb...");
    }
    out
    {
        assert(_isWall == true);
    }
    body
    {
        _isWall = true;
    }

    @property void removeWall() pure @safe @nogc
    in
    {
        assert(_isWall, "There is no wall on this cell...");
    }
    out
    {
        assert(_isWall == false);
    }
    body
    {
        _isWall = false;
    }

    @property void explode(uint color) pure @safe @nogc
    in
    {
        assert(!_isWall, "Trying to explode a wall...");
    }
    out
    {
        assert(_color == color);
        assert(_hasCharacter == false);
        assert(_hasBomb == false);
    }
    body
    {
        _hasCharacter = false;
        _hasBomb = false;
        _color = color;
    }


    invariant
    {
        assert(_isWall + (_hasCharacter || _hasBomb) <= 1,
               "Invalid cell: Cannot contain a wall and something else.");
    }

    pure @nogc unittest // Properties
    {
        Cell c;
        assert(c.color == 0);
        assert(c.hasCharacter == false);
        assert(c.hasBomb == false);
        assert(c.isWall == false);
        assert(c.isTraversable == true);

        c.addCharacter(1);
        assert(c.hasCharacter == true);
        assert(c.color == 1);

        c.addBomb;
        assert(c.hasBomb == true);

        c = Cell();
        c.addWall;
        assert(c.isWall);
    }

    pure unittest // Checks cell types validity
    {
        Cell empty, full, wall, c;
        full.addCharacter(1);
        full.addBomb;
        wall.addWall;
        assert(wall.isTraversable == false);

        // Characters and bombs can be in the same cell.
        // But Characters must be there first.
        c = empty;
        assert(c.isTraversable == true);
        c.addCharacter(1);
        assert(c.isTraversable == false);
        c.addBomb;
        assert(c.isTraversable == false);

        c = empty;
        c.addBomb;
        assert(c.isTraversable == false);
        assertThrown!AssertError(c.addCharacter(1));

        // Character and bombs can leave the cell in any order
        c = full;
        c.removeCharacter;
        c.removeBomb;

        c = full;
        c.removeBomb;
        c.removeCharacter;

        // No bombs nor Characters on walls!
        c = wall;
        assertThrown!AssertError(c.addCharacter(1));

        c = wall;
        assertThrown!AssertError(c.addBomb);

        // Walls can be removed
        c = wall;
        c.removeWall;
        assert(c.isWall == false);
        assertThrown!AssertError(c.removeWall);
    }

    string toString() const pure @safe
    {
        if (isWall)
            return "{wall}";
        else
        {
            string res = format!"{color=%d"(color);

            if (hasCharacter)
                res ~= ",char";
            if (hasBomb)
                res ~= ",bomb";

            res ~= "}";
            return res;
        }
    }
    pure @safe unittest
    {
        Cell c = Cell(32, true, false, false);
        assert(c.toString == "{color=32,char}");

        c = Cell(26, false, true, false);
        assert(c.toString == "{color=26,bomb}");

        c = Cell(12, true, true, false);
        assert(c.toString == "{color=12,char,bomb}");

        c = Cell(42, false, false, false);
        assert(c.toString == "{color=42}");

        c = Cell(0, false, false, true);
        assert(c.toString == "{wall}");
    }
}
