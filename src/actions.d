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
    bomb = "bomb"
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
        final switch (movement)
        {
            case CharacterMovement.move:
                direction = readDirectionString(v["direction"].str);
                return;
            case CharacterMovement.bomb:
                bombType = to!BombType(v["bomb_type"].str);
                bombRange = v["bomb_range"].getInt;
                bombDelay = v["bomb_delay"].getInt;

                checkBombProperties(bombType, bombRange, bombDelay);
                return;
            case CharacterMovement.revive:
                revivePosition.q = v["revive_q"].getInt;
                revivePosition.r = v["revive_r"].getInt;
                return;
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
}

struct PlayerActions
{
    uint color; // The color of the player that caused the actions
    CharacterActions[] actions; /// The characters' actions

    this(uint color, in JSONValue actionsArray)
    {
        this.color = color;
        parseActions(actionsArray);
    }

    private void parseActions(in JSONValue array)
    {
        enforce(array.type == JSON_TYPE.ARRAY,
            "actions is not an array");

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
        assert(pa.actions.length == 0);

        s = `[4]`;
        assertNotThrown(pa = PlayerActions(1, s.parseJSON));
        assert(pa.actions.length == 0);

        s = `[{"id":0, "movement":"revive", "revive_q":0, "revive_r":0}]`;
        assertNotThrown(pa = PlayerActions(1, s.parseJSON));
        assert(pa.actions.length == 1);

        s = `[{"id":0, "movement":"bomb", "bomb_type": "fat",
               "bomb_range":2, "bomb_delay":3, "direction":"x-"},
              {"id":0, "movement":"move", "direction":"z-"}]`;
        assertNotThrown(pa = PlayerActions(1, s.parseJSON));
        assert(pa.actions.length == 1);

        s = `[{"id":0, "movement":"move", "direction":"z+"},
              {"id":1, "movement":"move", "direction":"z-"}]`;
        assertNotThrown(pa = PlayerActions(1, s.parseJSON));
        assert(pa.actions.length == 2);
    }
}
