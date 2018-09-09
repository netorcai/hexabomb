import std.format;

import board : Position;

enum BombType : string
{
    thin = "thin",
    fat = "fat"
}

struct Bomb
{
    // Attributes
    private
    {
        Position _pos = Position(-42,-42);
        uint _color = 0;
        uint _range = 1;
        BombType _type = BombType.thin;
        uint _delay = 1;
    }

    // "Get" properties
    @property Position position() const pure @safe @nogc { return _pos; }
    @property uint color() const pure @safe @nogc { return _color; }
    @property uint range() const pure @safe @nogc { return _range; }
    @property BombType type() const pure @safe @nogc { return _type; }
    @property uint delay() const pure @safe @nogc { return _delay; }

    // "Set" properties
    @property void position(in Position pos) pure @safe @nogc
    out { assert(_pos == pos); }
    body { _pos = pos; }

    @property void color(in uint color) pure @safe @nogc
    out { assert(_color == color); }
    body { _color = color; }

    @property void range(in uint range) pure @safe @nogc
    out { assert(_range == range); }
    body { _range = range; }

    @property void type(in BombType type) pure @safe @nogc
    out { assert(_type == type); }
    body { _type = type; }

    @property void delay(in uint delay) pure @safe @nogc
    out { assert(_delay == delay); }
    body { _delay = delay; }

    unittest
    {
        Bomb b;
        assert(b.position == Position(-42,-42));
        assert(b.color == 0);
        assert(b.range == 1);
        assert(b.type == BombType.thin);
        assert(b.delay == 1);

        b.position = Position(0,0);
        assert(b.position == Position(0,0));

        b.color = 3;
        assert(b.color == 3);

        b.range = 5;
        assert(b.range == 5);

        b.type = BombType.fat;
        assert(b.type == BombType.fat);

        b.delay = 10;
        assert(b.delay == 10);
    }
}
