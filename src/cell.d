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
    }

    // "Get" properties
    @property uint color() const pure @safe @nogc { return _color; }
    @property bool hasCharacter() const pure @safe @nogc { return _hasCharacter; }
    @property bool hasBomb() const pure @safe @nogc { return _hasBomb; }
    @property bool isTraversable() const pure @safe @nogc
    {
        return !_hasCharacter && !_hasBomb;
    }

    // Character manipulations
    @property void addCharacter(uint color) pure @safe @nogc
    in
    {
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

    @property void explode(uint color) pure @safe @nogc
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


    pure @nogc unittest // Properties
    {
        Cell c;
        assert(c.color == 0);
        assert(c.hasCharacter == false);
        assert(c.hasBomb == false);
        assert(c.isTraversable == true);

        c.addCharacter(1);
        assert(c.hasCharacter == true);
        assert(c.color == 1);

        c.addBomb;
        assert(c.hasBomb == true);

        c.explode(4);
        assert(c.color == 4);
        assert(c.hasBomb == false);
        assert(c.hasCharacter == false);
    }

    pure unittest // Checks cell types validity
    {
        Cell empty, full, c;
        full.addCharacter(1);
        full.addBomb;

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
    }

    string toString() const pure @safe
    {
        string res = format!"{color=%d"(color);

        if (hasCharacter)
            res ~= ",char";
        if (hasBomb)
            res ~= ",bomb";

        res ~= "}";
        return res;
    }
    pure @safe unittest
    {
        Cell c = Cell(32, true, false);
        assert(c.toString == "{color=32,char}");

        c = Cell(26, false, true);
        assert(c.toString == "{color=26,bomb}");

        c = Cell(12, true, true);
        assert(c.toString == "{color=12,char,bomb}");

        c = Cell(42, false, false);
        assert(c.toString == "{color=42}");
    }
}
