import std.algorithm;
import std.conv;
import std.exception;
import std.experimental.logger;
import std.format;
import std.json;

import netorcai.json_util;

import bomb;
import board;

enum CharacterMovement : string
{
    revive = "revive",
    move = "move",
    bomb = "bomb",
    bombMove = "bombMove",
    moveBomb = "moveBomb"
}

bool isBombRelated(in CharacterMovement m) pure @nogc
{
    return m == CharacterMovement.bomb ||
        m == CharacterMovement.bombMove ||
        m == CharacterMovement.moveBomb;
}
unittest
{
    assert(!isBombRelated(CharacterMovement.move));
    assert(isBombRelated(CharacterMovement.bomb));
    assert(isBombRelated(CharacterMovement.bombMove));
    assert(isBombRelated(CharacterMovement.moveBomb));
}

bool isMoveRelated(in CharacterMovement m) pure @nogc
{
    return m == CharacterMovement.move ||
        m == CharacterMovement.bombMove ||
        m == CharacterMovement.moveBomb;
}
unittest
{
    assert(isMoveRelated(CharacterMovement.move));
    assert(!isMoveRelated(CharacterMovement.bomb));
    assert(isMoveRelated(CharacterMovement.bombMove));
    assert(isMoveRelated(CharacterMovement.moveBomb));
}

Direction readDirectionString(in string s) pure
{
    switch(s)
    {
        case "x+": return Direction.X_PLUS;
        case "y+": return Direction.Y_PLUS;
        case "z+": return Direction.Z_PLUS;
        case "x-": return Direction.X_MINUS;
        case "y-": return Direction.Y_MINUS;
        case "z-": return Direction.Z_MINUS;
        default: throw new Exception(format!"Cannot read direction='%s'"(s));
    }
}
unittest
{
    assert(readDirectionString(`x+`) == Direction.X_PLUS);
    assert(readDirectionString(`y+`) == Direction.Y_PLUS);
    assert(readDirectionString(`z+`) == Direction.Z_PLUS);
    assert(readDirectionString(`x-`) == Direction.X_MINUS);
    assert(readDirectionString(`y-`) == Direction.Y_MINUS);
    assert(readDirectionString(`z-`) == Direction.Z_MINUS);
    assertThrown(readDirectionString(`x—`));
    assertThrown(readDirectionString(`y+ `));
}

void checkBombProperties(in BombType bombType, in int bombRange, in int bombDelay)
{
    enforce(bombDelay >= 2 && bombDelay <= 4,
        format!"invalid bomb delay %s"(bombDelay));

    final switch (bombType)
    {
        case BombType.thin:
            enforce(bombRange >= 2 && bombRange <= 4,
                format!"invalid thin bomb range %s"(bombRange));
            break;
        case BombType.fat:
            enforce(bombRange == 2,
                format!"invalid fat bomb range %s"(bombRange));
    }
}

struct CharacterActions
{
    uint characterID;
    CharacterMovement movement;

    // Move related
    Direction direction;

    // Revive related
    Position revivePosition;

    // Bomb related
    BombType bombType;
    uint bombRange;
    uint bombDelay;

    this(JSONValue v)
    {
        enforce(v.type == JSON_TYPE.OBJECT,
            "CharacterActions value is not an object");
        characterID = v["id"].getInt;

        movement = to!CharacterMovement(v["movement"].str);
        if (movement.isMoveRelated)
            direction = readDirectionString(v["direction"].str);

        if (movement.isBombRelated)
        {
            bombType = to!BombType(v["bomb_type"].str);
            bombRange = v["bomb_range"].getInt;
            bombDelay = v["bomb_delay"].getInt;

            checkBombProperties(bombType, bombRange, bombDelay);
        }

        if (movement == CharacterMovement.revive)
        {
            revivePosition.q = v["revive_q"].getInt;
            revivePosition.r = v["revive_r"].getInt;
        }
    }
    unittest
    {
        string s = `[2]`;
        assertThrown(CharacterActions(s.parseJSON));
        assert(collectExceptionMsg(CharacterActions(s.parseJSON)) ==
            "CharacterActions value is not an object");

        s = `{}`;
        assertThrown(CharacterActions(s.parseJSON));
        assert(collectExceptionMsg(CharacterActions(s.parseJSON)) ==
            "Key not found: id");

        s = `{"id":0}`;
        assertThrown(CharacterActions(s.parseJSON));
        assert(collectExceptionMsg(CharacterActions(s.parseJSON)) ==
            "Key not found: movement");

        s = `{"id":0, "movement":"meh"}`;
        assertThrown(CharacterActions(s.parseJSON));
        assert(collectExceptionMsg(CharacterActions(s.parseJSON)) ==
            "CharacterMovement does not have a member named 'meh'");

        // Move
        s = `{"id":0, "movement":"move"}`;
        assertThrown(CharacterActions(s.parseJSON));
        assert(collectExceptionMsg(CharacterActions(s.parseJSON)) ==
            "Key not found: direction");

        s = `{"id":0, "movement":"move", "direction":"meh"}`;
        assertThrown(CharacterActions(s.parseJSON));
        assert(collectExceptionMsg(CharacterActions(s.parseJSON)) ==
            "Cannot read direction='meh'");

        s = `{"id":0, "movement":"move", "direction":"z+"}`;
        assertNotThrown(CharacterActions(s.parseJSON));

        // Bomb
        s = `{"id":0, "movement":"bomb"}`;
        assertThrown(CharacterActions(s.parseJSON));
        assert(collectExceptionMsg(CharacterActions(s.parseJSON)) ==
            "Key not found: bomb_type");

        s = `{"id":0, "movement":"bomb", "bomb_type": "meh"}`;
        assertThrown(CharacterActions(s.parseJSON));
        assert(collectExceptionMsg(CharacterActions(s.parseJSON)) ==
            "BombType does not have a member named 'meh'");

        s = `{"id":0, "movement":"bomb", "bomb_type": "thin"}`;
        assertThrown(CharacterActions(s.parseJSON));
        assert(collectExceptionMsg(CharacterActions(s.parseJSON)) ==
            "Key not found: bomb_range");

        s = `{"id":0, "movement":"bomb", "bomb_type": "thin",
            "bomb_range":2}`;
        assertThrown(CharacterActions(s.parseJSON));
        assert(collectExceptionMsg(CharacterActions(s.parseJSON)) ==
            "Key not found: bomb_delay");

        s = `{"id":0, "movement":"bomb", "bomb_type": "thin",
            "bomb_range":2, "bomb_delay":3}`;
        assertNotThrown(CharacterActions(s.parseJSON));

        s = `{"id":0, "movement":"bomb", "bomb_type": "thin",
            "bomb_range":2, "bomb_delay":1}`;
        assertThrown(CharacterActions(s.parseJSON));
        assert(collectExceptionMsg(CharacterActions(s.parseJSON)) ==
            "invalid bomb delay 1");

        s = `{"id":0, "movement":"bomb", "bomb_type": "thin",
            "bomb_range":2, "bomb_delay":5}`;
        assertThrown(CharacterActions(s.parseJSON));
        assert(collectExceptionMsg(CharacterActions(s.parseJSON)) ==
            "invalid bomb delay 5");

        s = `{"id":0, "movement":"bomb", "bomb_type": "thin",
            "bomb_range":1, "bomb_delay":3}`;
        assertThrown(CharacterActions(s.parseJSON));
        assert(collectExceptionMsg(CharacterActions(s.parseJSON)) ==
            "invalid thin bomb range 1");

        s = `{"id":0, "movement":"bomb", "bomb_type": "thin",
            "bomb_range":5, "bomb_delay":3}`;
        assertThrown(CharacterActions(s.parseJSON));
        assert(collectExceptionMsg(CharacterActions(s.parseJSON)) ==
            "invalid thin bomb range 5");

        s = `{"id":0, "movement":"bomb", "bomb_type": "fat",
            "bomb_range":1, "bomb_delay":3}`;
        assertThrown(CharacterActions(s.parseJSON));
        assert(collectExceptionMsg(CharacterActions(s.parseJSON)) ==
            "invalid fat bomb range 1");

        s = `{"id":0, "movement":"bomb", "bomb_type": "fat",
            "bomb_range":3, "bomb_delay":3}`;
        assertThrown(CharacterActions(s.parseJSON));
        assert(collectExceptionMsg(CharacterActions(s.parseJSON)) ==
            "invalid fat bomb range 3");

        // Revive
        s = `{"id":0, "movement":"revive"}`;
        assertThrown(CharacterActions(s.parseJSON));
        assert(collectExceptionMsg(CharacterActions(s.parseJSON)) ==
            "Key not found: revive_q");

        s = `{"id":0, "movement":"revive", "revive_q":4}`;
        assertThrown(CharacterActions(s.parseJSON));
        assert(collectExceptionMsg(CharacterActions(s.parseJSON)) ==
            "Key not found: revive_r");

        s = `{"id":0, "movement":"revive", "revive_q":4, "revive_r":"meh"}`;
        assertThrown(CharacterActions(s.parseJSON));
        assert(collectExceptionMsg(CharacterActions(s.parseJSON)) ==
            `Cannot read int value from JSONValue "meh"`);
    }

    CharacterActions[] parts() pure const
    out(r)
    {
        assert(r.length == 1 || r.length == 2);
    }
    body
    {
        final switch(movement)
        {
            case CharacterMovement.revive:
                return [this];
            case CharacterMovement.move:
                return [this];
            case CharacterMovement.bomb:
                return [this];
            case CharacterMovement.bombMove:
                CharacterActions bomb, move;
                extractBombAndMove(bomb, move);
                return [bomb, move];
            case CharacterMovement.moveBomb:
                CharacterActions bomb, move;
                extractBombAndMove(bomb, move);
                return [move, bomb];
        }
    }

    void extractBombAndMove(out CharacterActions bomb, out CharacterActions move) pure const
    in
    {
        assert(movement == CharacterMovement.bombMove ||
            movement == CharacterMovement.moveBomb);
    }
    out
    {
        assert(bomb.movement == CharacterMovement.bomb);
        assert(move.movement == CharacterMovement.move);
    }
    body
    {
        bomb = move = this;
        bomb.movement = CharacterMovement.bomb;
        move.movement = CharacterMovement.move;
    }
}

struct PlayerActions
{
    uint color; // The color of the player that caused the actions
    CharacterActions[] firstActions; /// Single actions or first part of bombMove and moveBomb
    CharacterActions[] secondActions; /// Second part of bombMove and moveBomb

    this(uint color, in JSONValue actionsArray)
    {
        this.color = color;
        parseActions(actionsArray);
    }

    private void parseActions(in JSONValue array)
    {
        enforce(array.type == JSON_TYPE.ARRAY,
            "actions is not an array");

        CharacterActions[] actions;
        foreach(e; array.array)
        {
            try
            {
                auto action = CharacterActions(e);
                if (any!((CharacterActions a) => a.characterID == action.characterID)(actions))
                    throw new Exception(format!"Several actions for id=%s"(action.characterID));
                actions ~= action;
            }
            catch (Exception e)
            {
                info("Ignoring a character action: ", e.msg);
            }
        }

        foreach(action; actions)
        {
            auto parts = action.parts;
            firstActions ~= parts[0];
            if (parts.length > 1)
                secondActions ~= parts[1];
        }
    }
    unittest
    {
        string s = `{}`;
        PlayerActions pa;
        assertThrown(PlayerActions(1, s.parseJSON));
        assert(collectExceptionMsg(PlayerActions(1, s.parseJSON)) ==
            `actions is not an array`);

        s = `[]`;
        assertNotThrown(pa = PlayerActions(1, s.parseJSON));
        assert(pa.firstActions.length == 0);
        assert(pa.secondActions.length == 0);

        s = `[4]`;
        assertNotThrown(pa = PlayerActions(1, s.parseJSON));
        assert(pa.firstActions.length == 0);
        assert(pa.secondActions.length == 0);

        s = `[{"id":0, "movement":"revive", "revive_q":0, "revive_r":0}]`;
        assertNotThrown(pa = PlayerActions(1, s.parseJSON));
        assert(pa.firstActions.length == 1);
        assert(pa.secondActions.length == 0);

        s = `[{"id":0, "movement":"bomb", "bomb_type": "fat",
               "bomb_range":2, "bomb_delay":3, "direction":"x-"},
              {"id":0, "movement":"move", "direction":"z-"}]`;
        assertNotThrown(pa = PlayerActions(1, s.parseJSON));
        assert(pa.firstActions.length == 1);
        assert(pa.secondActions.length == 0);

        s = `[{"id":0, "movement":"move", "direction":"z+"},
              {"id":1, "movement":"move", "direction":"z-"}]`;
        assertNotThrown(pa = PlayerActions(1, s.parseJSON));
        assert(pa.firstActions.length == 2);
        assert(pa.secondActions.length == 0);

        s = `[{"id":0, "movement":"move", "direction":"z+"},
              {"id":1, "movement":"bombMove", "bomb_type": "fat",
               "bomb_range":2, "bomb_delay":3, "direction":"x-"}]`;
        assertNotThrown(pa = PlayerActions(1, s.parseJSON));
        assert(pa.firstActions.length == 2);
        assert(pa.firstActions[0].movement == CharacterMovement.move);
        assert(pa.firstActions[1].movement == CharacterMovement.bomb);
        assert(pa.secondActions.length == 1);
        assert(pa.secondActions[0].movement == CharacterMovement.move);

        s = `[{"id":1, "movement":"moveBomb", "bomb_type": "fat",
               "bomb_range":2, "bomb_delay":3, "direction":"x-"},
              {"id":0, "movement":"move", "direction":"z+"}]`;
        assertNotThrown(pa = PlayerActions(1, s.parseJSON));
        assert(pa.firstActions.length == 2);
        assert(pa.firstActions[0].movement == CharacterMovement.move);
        assert(pa.firstActions[1].movement == CharacterMovement.move);
        assert(pa.secondActions.length == 1);
        assert(pa.secondActions[0].movement == CharacterMovement.bomb);
    }
}
