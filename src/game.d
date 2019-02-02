import core.exception : AssertError;
import std.algorithm;
import std.conv;
import std.exception;
import std.experimental.logger;
import std.format;
import std.json;
import std.range;
import std.typecons;

import netorcai.json_util;
import nm = netorcai.message;

import actions;
import board;
import bomb;
import cell;

struct Character
{
    immutable uint id;
    immutable uint color;
    bool alive = true;
    int reviveDelay = -1;
    int bombCount = 1;
    Position pos;
}

class Game
{
    private
    {
        Board _board;
        Bomb[] _bombs;
        Character[] _characters;

        uint _turnNumber = 0; // The turn number.
        uint _nbPlayers; /// The number of players in the game. 0 before init, then set to the right value
        uint[uint] _cellCount; /// The current number of cells of each player
        uint[uint] _score; /// The score of each player
        Position[][int] _initialPositions; /// Initial positions for each color
        Position[] _specialInitialPositions; /// Initial positions for the special player
        bool _isSuddenDeath; /// Whether the game is in normal or sudden death mode
    }

    invariant
    {
        assert(_cellCount.length == _nbPlayers + _isSuddenDeath);
        assert(_score.length == _nbPlayers + _isSuddenDeath);
    }

    this(in JSONValue initialMap)
    {
        enforce(initialMap.type == JSON_TYPE.OBJECT,
            "initial map is not an object");
        _board = new Board(initialMap["cells"]);

        auto initPos = initialMap["initial_positions"];
        enforce(initPos.type == JSON_TYPE.OBJECT,
            "initial_positions is not an object");
        foreach(key, value; initPos.object)
        {
            uint color;
            try { color = to!uint(key); }
            catch (Exception) { enforce(false, format!"invalid key='%s' in initial_positions"(key)); }

            enforce(value.type == JSON_TYPE.ARRAY,
                "initial positions are not an array for key=" ~ key);
            enforce(value.array.length > 0,
                "initial positions are empty for key=" ~ key);

            foreach(i, o; value.array)
            {
                enforce(o.type == JSON_TYPE.OBJECT,
                    "Element " ~ to!string(i) ~ " of initial_positions should be an object");
                Position p;
                p.q = o["q"].getInt;
                p.r = o["r"].getInt;

                _initialPositions[color] ~= p;
            }
        }

        if ("special_initial_positions" in initialMap)
        {
            auto specialInitPos = initialMap["special_initial_positions"];
            enforce(specialInitPos.type == JSON_TYPE.ARRAY,
                "special_initial_positions is not an array");
            foreach(i, o; specialInitPos.array)
            {
                enforce(o.type == JSON_TYPE.OBJECT,
                    "Element " ~ to!string(i) ~ " of special_initial_positions should be an object");
                Position p;
                p.q = o["q"].getInt;
                p.r = o["r"].getInt;

                _specialInitialPositions ~= p;
            }
        }

        checkInitialPositions(_initialPositions, _specialInitialPositions, _board);
    }
    unittest
    {
        string s = `[]`;
        Game g;
        assertThrown(new Game(s.parseJSON));
        assert(collectExceptionMsg(new Game(s.parseJSON)) ==
            "initial map is not an object");

        s = `{"cells":[], "initial_positions":4}`;
        assertThrown(new Game(s.parseJSON));
        assert(collectExceptionMsg(new Game(s.parseJSON)) ==
            "initial_positions is not an object");

        s = `{"cells":[], "initial_positions":{"bouh":1}}`;
        assertThrown(new Game(s.parseJSON));
        assert(collectExceptionMsg(new Game(s.parseJSON)) ==
            "invalid key='bouh' in initial_positions");

        s = `{"cells":[], "initial_positions":{"0":1}}`;
        assertThrown(new Game(s.parseJSON));
        assert(collectExceptionMsg(new Game(s.parseJSON)) ==
            "initial positions are not an array for key=0");

        s = `{"cells":[], "initial_positions":{"0":[]}}`;
        assertThrown(new Game(s.parseJSON));
        assert(collectExceptionMsg(new Game(s.parseJSON)) ==
            "initial positions are empty for key=0");

        s = `{"cells":[], "initial_positions":{"0":[4]}}`;
        assertThrown(new Game(s.parseJSON));
        assert(collectExceptionMsg(new Game(s.parseJSON)) ==
            "Element 0 of initial_positions should be an object");

        s = `{"cells":[{"q":1,"r":0}], "initial_positions":{"0":[{"q":1,"r":0}]}}`;
        assertNotThrown(g = new Game(s.parseJSON));
        assert(g._specialInitialPositions.length == 0);

        s = `{
          "cells":[{"q":1,"r":0},{"q":2,"r":0}],
          "initial_positions":{"0":[{"q":1,"r":0}]},
          "special_initial_positions":"meh"
        }`;
        assertThrown(new Game(s.parseJSON));
        assert(collectExceptionMsg(new Game(s.parseJSON)) ==
            "special_initial_positions is not an array");

        s = `{
          "cells":[{"q":1,"r":0},{"q":2,"r":0}],
          "initial_positions":{"0":[{"q":1,"r":0}]},
          "special_initial_positions":[4]
        }`;
        assertThrown(new Game(s.parseJSON));
        assert(collectExceptionMsg(new Game(s.parseJSON)) ==
            "Element 0 of special_initial_positions should be an object");

        s = `{
          "cells":[{"q":1,"r":0},{"q":2,"r":0}],
          "initial_positions":{"0":[{"q":1,"r":0}]},
          "special_initial_positions":[{"q":2,"r":0}]
        }`;
        assertNotThrown(g = new Game(s.parseJSON));
        assert(g._specialInitialPositions.length == 1);
    }

    /// Checks whether initial positions are fine. Throw Exception otherwise.
    static void checkInitialPositions(in Position[][int] positions,
        in Position[] specialPositions, in Board b)
    {
        enforce(positions.length > 0, "There are no initial positions");
        enforce(isPermutation(positions.keys(), iota(0, positions.length)),
            "Initial positions are missing for some players");
        enforce(positions.values.findAdjacent!"a.length != b.length".empty,
            "All players do not have the same number of positions");

        bool[Position] _marks;
        foreach(posArr ; positions)
        {
            foreach(pos ; posArr)
            {
                enforce(b.cellExists(pos),
                    "There is no cell at " ~ pos.toString);
                enforce(!(pos in _marks),
                    "Duplication of initial cell " ~ pos.toString);
                _marks[pos] = true;
            }
        }

        foreach(pos ; specialPositions)
        {
            enforce(b.cellExists(pos),
                    "There is no cell at " ~ pos.toString);
            enforce(!(pos in _marks),
                    "Duplication of initial cell " ~ pos.toString);
            _marks[pos] = true;
        }
    }
    unittest
    {
        Board b = generateEmptyBoard;
        Position[][int] positions;
        Position[] specialPositions;
        assertThrown(checkInitialPositions(positions,specialPositions,b));
        assert(collectExceptionMsg(checkInitialPositions(positions,specialPositions,b)) ==
            "There are no initial positions");

        positions = [
            0: [],
            1: [],
            3: []
        ];
        assertThrown(checkInitialPositions(positions,specialPositions,b));
        assert(collectExceptionMsg(checkInitialPositions(positions,specialPositions,b)) ==
            "Initial positions are missing for some players");

        positions = [
            0: [Position(0,0)],
            1: [Position(0,1)],
            2: [Position(0,2), Position(0,3)]
        ];
        assertThrown(checkInitialPositions(positions,specialPositions,b));
        assert(collectExceptionMsg(checkInitialPositions(positions,specialPositions,b)) ==
            "All players do not have the same number of positions");

        positions = [
            0: [Position(0,8)],
        ];
        assertThrown(checkInitialPositions(positions,specialPositions,b));
        assert(collectExceptionMsg(checkInitialPositions(positions,specialPositions,b))
            .startsWith("There is no cell at"));

        positions = [
            0: [Position(0,0)],
            1: [Position(0,1)],
            2: [Position(0,0)]
        ];
        assertThrown(checkInitialPositions(positions,specialPositions,b));
        assert(collectExceptionMsg(checkInitialPositions(positions,specialPositions,b))
            .startsWith("Duplication of initial cell"));

        positions = [
            0: [Position(0,0)],
            1: [Position(0,1)],
            2: [Position(0,2)]
        ];
        assertNotThrown(checkInitialPositions(positions,specialPositions,b));

        positions = [
            0: [Position(0,0)],
            1: [Position(0,1)],
            2: [Position(0,2)]
        ];
        specialPositions = [Position(0,8)];
        assertThrown(checkInitialPositions(positions,specialPositions,b));
        assert(collectExceptionMsg(checkInitialPositions(positions,specialPositions,b))
            .startsWith("There is no cell at"));

        positions = [
            0: [Position(0,0)],
            1: [Position(0,1)],
            2: [Position(0,2)]
        ];
        specialPositions = [Position(0,0)];
        assertThrown(checkInitialPositions(positions,specialPositions,b));
        assert(collectExceptionMsg(checkInitialPositions(positions,specialPositions,b))
            .startsWith("Duplication of initial cell"));

        positions = [
            0: [Position(0,0)],
            1: [Position(0,1)],
            2: [Position(0,2)]
        ];
        specialPositions = [Position(0,3)];
        assertNotThrown(checkInitialPositions(positions,specialPositions,b));
    }

    void updateScore()
    {
        // Update cell count.
        uint[uint] count = _board.cellCountPerColor;
        foreach(playerID, ref score; _score)
        {
            uint color = playerID + 1;
            if (color in count)
                _cellCount[playerID] = count[color];
            else
                _cellCount[playerID] = 0;
        }

        // Update alive character count.
        uint[uint] aliveCharacterCount;
        foreach(character; _characters.filter!(c => c.alive))
        {
            int playerID = character.color - 1;
            aliveCharacterCount[playerID] += 1;
        }

        // Update the score itself.
        foreach(playerID, ref score; _score)
        {
            if (_isSuddenDeath)
            {
                if (playerID in aliveCharacterCount)
                    score = _turnNumber;
            }
            else
                score += _cellCount[playerID];
        }
    }
    unittest
    {
        auto g = generateBasicGame;
        assert(g._score.length == 2);
        assert(g._score[0] == 0);
        assert(g._score[1] == 0);

        g.updateScore;
        assert(g._score[0] == 1);
        assert(g._score[1] == 1);

        g.updateScore;
        assert(g._score[0] == 2);
        assert(g._score[1] == 2);
    }

    private JSONValue describeScore() const
    out(r)
    {
        assert(r.type == JSON_TYPE.OBJECT);
    }
    body
    {
        JSONValue v = `{}`.parseJSON;

        foreach(playerID, score; _score)
        {
            v.object[to!string(playerID)] = cast(int)score;
        }

        return v;
    }
    unittest
    {
        auto g = generateBasicGame;
        string s = `{
          "0": 0,
          "1": 0
        }`;
        assert(g.describeScore.toString == s.parseJSON.toString);

        g._score.clear;
        s = `{}`;
        assert(g.describeScore.toString == s.parseJSON.toString);

        g._score = [0:5, 1:10, 2:27];
        s = `{
          "0": 5,
          "1": 10,
          "2": 27
        }`;
        assert(g.describeScore.toString == s.parseJSON.toString);
    }

    private JSONValue describeCellCount() const
    out(r)
    {
        assert(r.type == JSON_TYPE.OBJECT);
    }
    body
    {
        JSONValue v = `{}`.parseJSON;

        foreach(playerID, nbCells; _cellCount)
        {
            v.object[to!string(playerID)] = cast(int)nbCells;
        }

        return v;
    }
    unittest
    {
        auto g = generateBasicGame;
        string s = `{
          "0": 1,
          "1": 1
        }`;
        assert(g.describeCellCount.toString == s.parseJSON.toString);

        g._cellCount.clear;
        s = `{}`;
        assert(g.describeCellCount.toString == s.parseJSON.toString);

        g._cellCount = [0:5, 1:10, 2:27];
        s = `{
          "0": 5,
          "1": 10,
          "2": 27
        }`;
        assert(g.describeCellCount.toString == s.parseJSON.toString);
    }

    void initializeGame(in int nbPlayers, in int nbSpecialPlayers)
    in
    {
        assert(_score.length == 0);
        assert(_cellCount.length == 0);
    }
    out
    {
        assert(_score.length == nbPlayers+nbSpecialPlayers);
        assert(_cellCount.length == nbPlayers+nbSpecialPlayers);
        _score.each!(s => assert(s == 0));
        _cellCount.each!(c => assert(c > 0));
    }
    body
    {
        enforce(nbSpecialPlayers == 0 || nbSpecialPlayers == 1,
            "hexabomb only supports 0 or 1 special players");
        enforce((nbSpecialPlayers == 0) || (_specialInitialPositions.length > 0),
            "loaded map does not support sudden death mode");
        _nbPlayers = nbPlayers;
        _isSuddenDeath = (nbSpecialPlayers == 1);
        iota(0,nbPlayers+_isSuddenDeath).each!(playerID => _score[playerID] = 0);
        placeInitialCharacters(nbPlayers);

        uint[uint] count = _board.cellCountPerColor;
        foreach(playerID, ref score; _score)
        {
            uint color = playerID + 1;
            _cellCount[playerID] = count[color];
        }
    }
    unittest
    {
        string s = `{
          "cells":[
            {"q":0, "r":0}
          ],
          "initial_positions":{
            "0": [{"q":0, "r":0}]
          }
        }`;
        Game g = new Game(s.parseJSON);
        assertThrown(g.initializeGame(1, 2));
        assert(collectExceptionMsg(g.initializeGame(1, 2)) ==
            "hexabomb only supports 0 or 1 special players");

        assertThrown(g.initializeGame(1, 1));
        assert(collectExceptionMsg(g.initializeGame(1, 1)) ==
            "loaded map does not support sudden death mode");
    }

    // Generate the initial characters. Throw Exception on error
    private void placeInitialCharacters(in int nbPlayers)
    in
    {
        assert(_characters.empty);
    }
    out
    {
        foreach(c; _characters)
            assert(_board.cellAt(c.pos).hasCharacter);
    }
    body
    {
        enforce(_initialPositions.length >= nbPlayers,
            format!"Too many players (%d) for this map (max=%d)."(
                nbPlayers, _initialPositions.length));

        uint characterID = 0;
        if (_isSuddenDeath)
        {
            foreach(pos; _specialInitialPositions)
            {
                Character c = {id: characterID, color:1, pos:pos};
                _board.cellAt(c.pos).addCharacter(c.color);
                _characters ~= c;
                characterID += 1;
            }
        }

        foreach(playerID; 0..nbPlayers)
        {
            foreach(pos; _initialPositions[playerID])
            {
                Character c = {id: characterID, color:playerID+1+_isSuddenDeath, pos:pos};
                _board.cellAt(c.pos).addCharacter(c.color);
                _characters ~= c;
                characterID += 1;
            }
        }
    }
    unittest
    {
        Game g = new Game(`{
          "cells":[
            {"q":0, "r":0}
          ],
          "initial_positions":{
            "0": [{"q":0, "r":0}]
          }
        }`.parseJSON);
        assertThrown(g.placeInitialCharacters(2));
        assertNotThrown(g.placeInitialCharacters(1));
        assert(g._characters[0].pos == Position(0,0));

        g = new Game(`{
          "cells":[
            {"q":0, "r":0},
            {"q":1, "r":0}
          ],
          "initial_positions":{
            "0": [{"q":0, "r":0}]
          },
          "special_initial_positions":[{"q":1, "r":0}]
        }`.parseJSON);
        g._isSuddenDeath = false;
        assertNotThrown(g.placeInitialCharacters(1));
        assert(g._characters[0].pos == Position(0,0));
        assert(g._characters[0].color == 1);
        assert(g._board.cellAt(Position(0,0)).color == 1);
        assert(g._board.cellAt(Position(1,0)).color == 0);
        assert( g._board.cellAt(Position(0,0)).hasCharacter);
        assert(!g._board.cellAt(Position(1,0)).hasCharacter);

        g = new Game(`{
          "cells":[
            {"q":0, "r":0},
            {"q":1, "r":0}
          ],
          "initial_positions":{
            "0": [{"q":0, "r":0}]
          },
          "special_initial_positions":[{"q":1, "r":0}]
        }`.parseJSON);
        g._isSuddenDeath = true;
        assertNotThrown(g.placeInitialCharacters(1));
        assert(g._characters[0].pos == Position(1,0));
        assert(g._characters[1].pos == Position(0,0));
        assert(g._characters[0].color == 1);
        assert(g._characters[1].color == 2);
        assert(g._board.cellAt(Position(0,0)).color == 2);
        assert(g._board.cellAt(Position(1,0)).color == 1);
        assert(g._board.cellAt(Position(0,0)).hasCharacter);
        assert(g._board.cellAt(Position(1,0)).hasCharacter);
    }

    /// Generate a JSON description of the current characters
    private JSONValue describeCharacters() pure const
    out(r)
    {
        assert(r.type == JSON_TYPE.ARRAY);
    }
    body
    {
        JSONValue v = `[]`.parseJSON;

        foreach(c; _characters)
        {
            JSONValue cValue = `{}`.parseJSON;
            cValue.object["id"] = c.id;
            cValue.object["color"] = c.color;
            cValue.object["q"] = c.pos.q;
            cValue.object["r"] = c.pos.r;
            cValue.object["alive"] = c.alive;
            cValue.object["revive_delay"] = c.reviveDelay;
            cValue.object["bomb_count"] = c.bombCount;

            v.array ~= cValue;
        }

        return v;
    }

    private JSONValue describeBombs() pure const
    out(r)
    {
        assert(r.type == JSON_TYPE.ARRAY);
    }
    body
    {
        JSONValue v = `[]`.parseJSON;

        foreach(b; _bombs)
        {
            JSONValue cValue = `{}`.parseJSON;
            cValue.object["color"] = b.color;
            cValue.object["range"] = b.range;
            cValue.object["delay"] = b.delay;
            cValue.object["q"] = b.position.q;
            cValue.object["r"] = b.position.r;

            v.array ~= cValue;
        }

        return v;
    }
    unittest
    {
        Game g = new Game(`{
          "cells":[
            {"q":0, "r":0},
            {"q":0, "r":1}
          ],
          "initial_positions":{
            "0": [{"q":0, "r":0}]
          }
        }`.parseJSON);
        assert(g.describeBombs == `[]`.parseJSON);

        g._bombs ~= Bomb(Position(0,1), 3, 5, 7);
        assert(g.describeBombs.toString ==
            `[{"q":0, "r":1, "color":3, "range":5, "delay":7}]`
            .parseJSON.toString);

        g._bombs ~= Bomb(Position(0,2), 4, 2, 2);
        assert(g.describeBombs.toString ==
            `[{"q":0, "r":1, "color":3, "range":5, "delay":7},
              {"q":0, "r":2, "color":4, "range":2, "delay":2}]`
            .parseJSON.toString);
    }

    /// Generate a JSON description of the current game state
    JSONValue describeState() const
    out(r)
    {
        assert(r.type == JSON_TYPE.OBJECT);
    }
    body
    {
        JSONValue v = `{}`.parseJSON;
        v.object["cells"] = _board.toJSON;
        v.object["characters"] = describeCharacters;
        v.object["bombs"] = describeBombs;
        v.object["score"] = describeScore;
        v.object["cell_count"] = describeCellCount;

        return v;
    }
    unittest
    {
        Game g = new Game(`{
          "cells":[
            {"q":0, "r":0},
            {"q":0, "r":1},
            {"q":0, "r":2}
          ],
          "initial_positions":{
            "0": [{"q":0, "r":0}],
            "1": [{"q":0, "r":1}]
          }
        }`.parseJSON);
        g.initializeGame(2, 0);
        assert(g.describeState.toString == `{
            "bombs": [],
            "cells":[
              {"q":0, "r":0, "color":1},
              {"q":0, "r":1, "color":2},
              {"q":0, "r":2, "color":0}
            ],
            "characters":[
              {"id":0, "color":1, "q":0, "r":0, "alive":true, "revive_delay":-1, "bomb_count": 1},
              {"id":1, "color":2, "q":0, "r":1, "alive":true, "revive_delay":-1, "bomb_count": 1}
            ],
            "score":{
              "0": 0,
              "1": 0
            },
            "cell_count":{
              "0": 1,
              "1": 1
            }
          }`.parseJSON.toString);
    }

    void doTurn(in nm.DoTurnMessage msg, out int currentWinnerPlayerID, out JSONValue gameState)
    {
        _turnNumber += 1;

        // Retrieve the players actions as the Game understands it
        PlayerActions[] playerActions = msg.playerActions.map!(npa => PlayerActions(npa.playerID + 1, npa.actions)).array;

        // Update the game state (apply the players' actions)
        applyPlayersActions(playerActions);

        // Manage dead characters: reduce delays.
        doDeadCharacterTurn;

        // Increase the bombCount of characters?
        updateCharactersBombCount;

        // Manage bombs: reduce delays, compute explosions...
        doBombTurn;

        // Compute score
        updateScore;

        // Determine the current winner (if any)
        currentWinnerPlayerID = determineCurrentWinnerPlayerID;

        // Update the game state description
        gameState = describeState;
    }
    unittest // Classical game mode
    {
        auto g = generateBasicGame;
        JSONValue gameState;
        nm.DoTurnMessage doTurnMsg;
        int currentWinnerPlayerID;

        assert(g._characters[0].pos == Position(0,0)); // Initial position
        assert(g._characters[1].pos == Position(0,1)); // Initial position

        // No action
        doTurnMsg = nm.parseDoTurnMessage(`{
          "message_type": "DO_TURN",
          "player_actions": []
        }`.parseJSON);
        assertNotThrown(g.doTurn(doTurnMsg, currentWinnerPlayerID, gameState));
        assert(g._characters[0].pos == Position(0,0)); // Did not move
        assert(g._characters[1].pos == Position(0,1)); // Did not move
        assert(currentWinnerPlayerID == -1);
        assert(gameState["cell_count"]["0"].getInt == 1);
        assert(gameState["cell_count"]["1"].getInt == 1);
        assert(gameState["score"]["0"].getInt == 1);
        assert(gameState["score"]["1"].getInt == 1);

        // Adjacent move. Both characters should move.
        doTurnMsg = nm.parseDoTurnMessage(`{
          "message_type": "DO_TURN",
          "player_actions": [
            {"player_id": 0, "turn_number": 1, "actions":[{"id":0, "movement":"move", "direction":"z-"}]},
            {"player_id": 1, "turn_number": 1, "actions":[{"id":1, "movement":"move", "direction":"z-"}]}
          ]
        }`.parseJSON);
        assertNotThrown(g.doTurn(doTurnMsg, currentWinnerPlayerID, gameState));
        assert(g._characters[0].pos == Position(0,1)); // Moved
        assert(g._characters[1].pos == Position(0,2)); // Moved
        assert(currentWinnerPlayerID == 0);
        assert(gameState["cell_count"]["0"].getInt == 2);
        assert(gameState["cell_count"]["1"].getInt == 1);
        assert(gameState["score"]["0"].getInt == 3);
        assert(gameState["score"]["1"].getInt == 2);

        // Moving into the same cell. First character to move should win. In this case, character 1 from player_id 1.
        doTurnMsg = nm.parseDoTurnMessage(`{
          "message_type": "DO_TURN",
          "player_actions": [
            {"player_id": 1, "turn_number": 2, "actions":[{"id":1, "movement":"move", "direction":"y+"}]},
            {"player_id": 0, "turn_number": 2, "actions":[{"id":0, "movement":"move", "direction":"x+"}]}
          ]
        }`.parseJSON);
        assertNotThrown(g.doTurn(doTurnMsg, currentWinnerPlayerID, gameState));
        assert(g._characters[0].pos == Position(0,1)); // Did not move
        assert(g._characters[1].pos == Position(1,1)); // Moved
        assert(currentWinnerPlayerID == 0);
        assert(gameState["cell_count"]["0"].getInt == 2);
        assert(gameState["cell_count"]["1"].getInt == 2);
        assert(gameState["score"]["0"].getInt == 5);
        assert(gameState["score"]["1"].getInt == 4);

        // 1. char0 spawns a bomb on its current location
        // 2. char1 moves into char0. This should NOT succeed
        doTurnMsg = nm.parseDoTurnMessage(`{
          "message_type": "DO_TURN",
          "player_actions": [
            {"player_id": 0, "turn_number": 3, "actions":[{"id":0, "movement":"bomb", "bomb_range":2, "bomb_delay":2}]},
            {"player_id": 1, "turn_number": 3, "actions":[{"id":1, "movement":"move", "direction":"x-"}]}
          ]
        }`.parseJSON);
        assertNotThrown(g.doTurn(doTurnMsg, currentWinnerPlayerID, gameState));
        assert(g._characters[0].pos == Position(0,1)); // Did not move
        assert(g._characters[0].bombCount == 0); // Decreased
        assert(g._characters[1].pos == Position(1,1)); // Move failed
        assert(g._characters[1].bombCount == 1); // Remained the same
        assert(g._board.cellAt(Position(0,1)).hasBomb == true); // Bomb succeeded
        assert(g._board.cellAt(Position(1,1)).hasBomb == false);
        assert(g._board.cellAt(Position(0,1)).color == 1);
        assert(g._board.cellAt(Position(1,1)).color == 2);
        assert(gameState["bombs"].array.length == 1);
        assert(currentWinnerPlayerID == 0);
        assert(gameState["cell_count"]["0"].getInt == 2);
        assert(gameState["cell_count"]["1"].getInt == 2);
        assert(gameState["score"]["0"].getInt == 7);
        assert(gameState["score"]["1"].getInt == 6);

        // Invalid moves. No action should be done this turn.
        // - player0 action does not exist. This should be wiped out.
        // - player1 tries to move the opponent's character. This should be ignored.
        doTurnMsg = nm.parseDoTurnMessage(`{
          "message_type": "DO_TURN",
          "player_actions": [
            {"player_id": 0, "turn_number": 4, "actions":[{"id":0, "movement":"win"}]},
            {"player_id": 1, "turn_number": 4, "actions":[{"id":0, "movement":"move", "direction":"x-"}]}
          ]
        }`.parseJSON);
        assertNotThrown(g.doTurn(doTurnMsg, currentWinnerPlayerID, gameState));
        assert(g._characters[0].pos == Position(0,1)); // Did not move
        assert(g._characters[1].pos == Position(1,1)); // Did not move
        assert(currentWinnerPlayerID == 0);
        assert(gameState["bombs"].array.length == 1);
        assert(gameState["cell_count"]["0"].getInt == 2);
        assert(gameState["cell_count"]["1"].getInt == 2);
        assert(gameState["score"]["0"].getInt == 9);
        assert(gameState["score"]["1"].getInt == 8);

        // char1 moves to avoid the explosion of this turn. char0 moves but still dies from the explosion.
        doTurnMsg = nm.parseDoTurnMessage(`{
          "message_type": "DO_TURN",
          "player_actions": [
            {"player_id": 0, "turn_number": 5, "actions":[{"id":0, "movement":"move", "direction":"x+"}]},
            {"player_id": 1, "turn_number": 5, "actions":[{"id":1, "movement":"move", "direction":"y+"}]}
          ]
        }`.parseJSON);
        assertNotThrown(g.doTurn(doTurnMsg, currentWinnerPlayerID, gameState));
        assert(g._characters[0].pos == Position( 1, 1)); // Moved
        assert(g._characters[0].alive == false); // Died
        assert(g._characters[0].reviveDelay == 3); // Died
        assert(g._characters[1].pos == Position( 2, 0)); // Moved
        assert(g._characters[1].alive == true);

        assert(g._board.cellAt(Position( 0, 1)).color == 1); // dist=0
        assert(g._board.cellAt(Position( 1, 1)).color == 1); // dist=1 x+
        assert(g._board.cellAt(Position( 2, 1)).color == 1); // dist=2 x+
        assert(g._board.cellAt(Position( 1, 0)).color == 1); // dist=1 y+
        assert(g._board.cellAt(Position( 2,-1)).color == 1); // dist=2 y+
        assert(g._board.cellAt(Position( 0, 0)).color == 1); // dist=1 z+
        assert(g._board.cellAt(Position( 0,-1)).color == 1); // dist=2 z+

        assert(g._board.cellAt(Position(-1, 1)).color == 1); // dist=1 x-
        assert(g._board.cellAt(Position(-2, 1)).color == 1); // dist=2 x-
        assert(g._board.cellAt(Position(-1, 2)).color == 1); // dist=1 y-
        assert(g._board.cellAt(Position(-2, 3)).color == 1); // dist=2 y-
        assert(g._board.cellAt(Position( 0, 2)).color == 1); // dist=1 z-
        assert(g._board.cellAt(Position( 0, 3)).color == 1); // dist=2 z-

        assert(currentWinnerPlayerID == 0);
        assert(gameState["bombs"].array.length == 0);
        assert(gameState["cell_count"]["0"].getInt == 13);
        assert(gameState["cell_count"]["1"].getInt == 1);
        assert(gameState["score"]["0"].getInt == 22);
        assert(gameState["score"]["1"].getInt == 9);

        // char1 just moves to char0's position then stops — just waiting for char0 to be revivable.
        doTurnMsg = nm.parseDoTurnMessage(`{
          "message_type": "DO_TURN",
          "player_actions": [
            {"player_id": 0, "turn_number": 7, "actions":[]},
            {"player_id": 1, "turn_number": 7, "actions":[{"id":1, "movement":"move", "direction":"y-"}]}
          ]
        }`.parseJSON);
        assertNotThrown(g.doTurn(doTurnMsg, currentWinnerPlayerID, gameState));
        assert(g._characters[0].reviveDelay == 2);
        assert(g._characters[1].pos == Position( 1, 1)); // Moved
        assert(g._characters[1].pos == g._characters[0].pos);
        assert(gameState["cell_count"]["0"].getInt == 12);
        assert(gameState["cell_count"]["1"].getInt == 2);
        assert(gameState["score"]["0"].getInt == 34);
        assert(gameState["score"]["1"].getInt == 11);

        doTurnMsg = nm.parseDoTurnMessage(`{
          "message_type": "DO_TURN",
          "player_actions": [
            {"player_id": 0, "turn_number": 8, "actions":[]},
            {"player_id": 1, "turn_number": 8, "actions":[]}
          ]
        }`.parseJSON);
        assertNotThrown(g.doTurn(doTurnMsg, currentWinnerPlayerID, gameState));
        assert(g._characters[0].reviveDelay == 1);
        assert(gameState["score"]["0"].getInt == 46);
        assert(gameState["score"]["1"].getInt == 13);

        doTurnMsg = nm.parseDoTurnMessage(`{
          "message_type": "DO_TURN",
          "player_actions": [
            {"player_id": 0, "turn_number": 9, "actions":[]},
            {"player_id": 1, "turn_number": 9, "actions":[]}
          ]
        }`.parseJSON);
        assertNotThrown(g.doTurn(doTurnMsg, currentWinnerPlayerID, gameState));
        assert(g._characters[0].bombCount == 0); // Still the same
        assert(g._characters[0].reviveDelay == 0);
        assert(g._characters[1].bombCount == 1); // Still the same
        assert(gameState["score"]["0"].getInt == 58);
        assert(gameState["score"]["1"].getInt == 15);

        // Revive and move.
        // - char0 tries to revive. char1 must first move to enable this.
        // - char1 just moves.
        doTurnMsg = nm.parseDoTurnMessage(`{
          "message_type": "DO_TURN",
          "player_actions": [
            {"player_id": 0, "turn_number": 10, "actions":[{"id":0, "movement":"revive"}]},
            {"player_id": 1, "turn_number": 10, "actions":[{"id":1, "movement":"move", "direction":"y+"}]}
          ]
        }`.parseJSON);
        assertNotThrown(g.doTurn(doTurnMsg, currentWinnerPlayerID, gameState));
        assert(g._turnNumber == 10);
        assert(g._characters[0].pos == Position( 1, 1)); // Did not moved
        assert(g._characters[0].alive == true); // Revived
        assert(g._characters[0].reviveDelay == -1); // Revived
        assert(g._characters[0].bombCount == 1); // Increased
        assert(g._characters[1].pos == Position( 2, 0)); // Moved
        assert(g._characters[1].alive == true);
        assert(g._characters[1].bombCount == 2); // Increased
        assert(g._board.cellAt(Position( 1, 1)).color == 1);
        assert(g._board.cellAt(Position( 2, 0)).color == 2);
        assert(gameState["cell_count"]["0"].getInt == 13);
        assert(gameState["cell_count"]["1"].getInt == 1);
        assert(gameState["score"]["0"].getInt == 71);
        assert(gameState["score"]["1"].getInt == 16);

        // Do nothing for 9 turns. Bomb count should remain the same.
        foreach(i; 1 .. 10)
        {
            doTurnMsg = nm.parseDoTurnMessage(`{
              "message_type": "DO_TURN",
              "player_actions": []
            }`.parseJSON);
            assertNotThrown(g.doTurn(doTurnMsg, currentWinnerPlayerID, gameState));

            assert(g._characters[0].bombCount == 1);
            assert(g._characters[1].bombCount == 2);
        }

        // The bomb count is increased next turn. But char1 already has 2 bombs.
        doTurnMsg = nm.parseDoTurnMessage(`{
          "message_type": "DO_TURN",
          "player_actions": []
        }`.parseJSON);
        assertNotThrown(g.doTurn(doTurnMsg, currentWinnerPlayerID, gameState));

        assert(g._turnNumber == 20);
        assert(g._characters[0].bombCount == 2); // Increased
        assert(g._characters[1].bombCount == 2);
    }
    unittest // Sudden death game mode
    {
        auto g = generateSuddenDeathGame;
        JSONValue gameState;
        nm.DoTurnMessage doTurnMsg;
        int currentWinnerPlayerID;

        // Initial state.
        assert(g._isSuddenDeath == true);
        assert(g._characters.length == 3);
        assert(g._characters[0].color == 1); // special player
        assert(g._characters[0].pos == Position( 0, 0));
        assert(g._characters[1].color == 2); // player1
        assert(g._characters[1].pos == Position(-1, 0));
        assert(g._characters[2].color == 3); // player2
        assert(g._characters[2].pos == Position( 1, 0));
        assert(g._score[0] == 0);
        assert(g._score[1] == 0);
        assert(g._score[2] == 0);

        /+ First turn.
           - All characters try to drop an overpowered bomb.
           - Only the special character succeeds in doing it.
        +/
        doTurnMsg = nm.parseDoTurnMessage(`{
          "message_type": "DO_TURN",
          "player_actions": [
            {"player_id": 0, "turn_number": 1, "actions":[{"id":0, "movement":"bomb", "bomb_range":100, "bomb_delay":100}]},
            {"player_id": 1, "turn_number": 1, "actions":[{"id":1, "movement":"bomb", "bomb_range":100, "bomb_delay":100}]},
            {"player_id": 2, "turn_number": 1, "actions":[{"id":2, "movement":"bomb", "bomb_range":100, "bomb_delay":100}]}
          ]
        }`.parseJSON);
        assertNotThrown(g.doTurn(doTurnMsg, currentWinnerPlayerID, gameState));
        assert( g._board.cellAt(Position( 0, 0)).hasBomb); // success (special player)
        assert(!g._board.cellAt(Position(-1, 0)).hasBomb); // failure (normal player 1)
        assert(!g._board.cellAt(Position( 1, 0)).hasBomb); // failure (normal player 2)
        assert(g._characters[0].pos == Position( 0, 0));
        assert(g._characters[1].pos == Position(-1, 0));
        assert(g._characters[2].pos == Position( 1, 0));
        assert(g._score[0] == 1);
        assert(g._score[1] == 1);
        assert(g._score[2] == 1);

        /+ Second turn.
           - Special character moves up and right (y+)
           - Player1 tries to move right (x+)but this fails (because of a bomb there)
           - Player2 does nothing (does not reply in time =/)
        +/
        doTurnMsg = nm.parseDoTurnMessage(`{
          "message_type": "DO_TURN",
          "player_actions": [
            {"player_id": 0, "turn_number": 2, "actions":[{"id":0, "movement":"move", "direction":"y+"}]},
            {"player_id": 1, "turn_number": 2, "actions":[{"id":1, "movement":"move", "direction":"x+"}]}
          ]
        }`.parseJSON);
        assertNotThrown(g.doTurn(doTurnMsg, currentWinnerPlayerID, gameState));
        assert(g._characters[0].pos == Position( 1,-1)); // moved
        assert(g._characters[1].pos == Position(-1, 0)); // move failed
        assert(g._characters[2].pos == Position( 1, 0)); // no action
        assert(g._score[0] == 2);
        assert(g._score[1] == 2);
        assert(g._score[2] == 2);

        /+ Third turn.
           - All players drop a small bomb (delay=3,range=2) and succeed in doing so.
        +/
        doTurnMsg = nm.parseDoTurnMessage(`{
          "message_type": "DO_TURN",
          "player_actions": [
            {"player_id": 0, "turn_number": 3, "actions":[{"id":0, "movement":"bomb", "bomb_range":2, "bomb_delay":3}]},
            {"player_id": 1, "turn_number": 3, "actions":[{"id":1, "movement":"bomb", "bomb_range":2, "bomb_delay":3}]},
            {"player_id": 2, "turn_number": 3, "actions":[{"id":2, "movement":"bomb", "bomb_range":2, "bomb_delay":3}]}
          ]
        }`.parseJSON);
        assertNotThrown(g.doTurn(doTurnMsg, currentWinnerPlayerID, gameState));
        assert(g._characters[0].pos == Position( 1,-1)); // no move action
        assert(g._characters[1].pos == Position(-1, 0)); // no move action
        assert(g._characters[2].pos == Position( 1, 0)); // no move action
        assert(g._board.cellAt(Position( 1,-1)).hasBomb); // new bomb
        assert(g._board.cellAt(Position(-1, 0)).hasBomb); // new bomb
        assert(g._board.cellAt(Position( 1, 0)).hasBomb); // new bomb
        assert(g._score[0] == 3);
        assert(g._score[1] == 3);
        assert(g._score[2] == 3);

        /+ Fourth turn.
           - Special player drops a bomb and succeeds in doing so.
           - Other players move in a direction and succeed in doing so.
        +/
        doTurnMsg = nm.parseDoTurnMessage(`{
          "message_type": "DO_TURN",
          "player_actions": [
            {"player_id": 0, "turn_number": 4, "actions":[{"id":0, "movement":"bomb", "bomb_range":2, "bomb_delay":2}]},
            {"player_id": 1, "turn_number": 4, "actions":[{"id":1, "movement":"move", "direction":"x-"}]},
            {"player_id": 2, "turn_number": 4, "actions":[{"id":2, "movement":"move", "direction":"x+"}]}
          ]
        }`.parseJSON);
        assertNotThrown(g.doTurn(doTurnMsg, currentWinnerPlayerID, gameState));
        assert(g._characters[0].pos == Position( 1,-1)); // no move action
        assert(g._characters[1].pos == Position(-2, 0)); // moved
        assert(g._characters[2].pos == Position( 2, 0)); // moved
        assert( g._board.cellAt(Position( 1,-1)).hasBomb); // new bomb
        assert(g._score[0] == 4);
        assert(g._score[1] == 4);
        assert(g._score[2] == 4);

        /+ Fifth turn.
           - Special player tries to drop another bomb and succeeds.
           - Player 1 tries to drop another bomb but fails (its bomb count is 0).
           - Player 2 moves away from bombs.
        +/
        doTurnMsg = nm.parseDoTurnMessage(`{
          "message_type": "DO_TURN",
          "player_actions": [
            {"player_id": 0, "turn_number": 5, "actions":[{"id":0, "movement":"move", "direction":"x+"}]},
            {"player_id": 1, "turn_number": 5, "actions":[{"id":1, "movement":"bomb", "bomb_range":2, "bomb_delay":2}]},
            {"player_id": 2, "turn_number": 5, "actions":[{"id":2, "movement":"move", "direction":"z-"}]}
          ]
        }`.parseJSON);
        assertNotThrown(g.doTurn(doTurnMsg, currentWinnerPlayerID, gameState));
        assert(g._characters[0].pos == Position( 2,-1)); // moved
        assert(g._characters[1].pos == Position(-2, 0)); // no move action
        assert(g._characters[2].pos == Position( 2, 1)); // moved
        assert(!g._board.cellAt(Position(-2, 0)).hasBomb); // no new bomb (fail)
        assert(g._score[0] == 5);
        assert(g._score[1] == 5);
        assert(g._score[2] == 5);

        /+ Sixth turn.
          - All bombs explode.
          - Player 1 is killed in the explosions.
          - Player 2 survives.
        +/
        doTurnMsg = nm.parseDoTurnMessage(`{
          "message_type": "DO_TURN",
          "player_actions": [
            {"player_id": 0, "turn_number": 6, "actions":[]},
            {"player_id": 1, "turn_number": 6, "actions":[]},
            {"player_id": 2, "turn_number": 6, "actions":[]}
          ]
        }`.parseJSON);
        assertNotThrown(g.doTurn(doTurnMsg, currentWinnerPlayerID, gameState));
        assert(g._characters[0].pos == Position( 2,-1)); // no move action
        assert(g._characters[1].pos == Position(-2, 0)); // no move action
        assert(g._characters[2].pos == Position( 2, 1)); // no move action
        assert( g._characters[0].alive); // special player is immune to bombs
        assert(!g._characters[1].alive); // normal player is not
        assert( g._characters[2].alive); // this one was not in an explosion range
        assert(g._characters[1].reviveDelay == 3);
        assert(g._bombs.length == 0);
        assert(g._score[0] == 6);
        assert(g._score[1] == 5); // dead!
        assert(g._score[2] == 6);

        /+ Seventh turn.
           - Special player drops a bomb that will kill the remaining player.
        +/
        doTurnMsg = nm.parseDoTurnMessage(`{
          "message_type": "DO_TURN",
          "player_actions": [
            {"player_id": 0, "turn_number": 7, "actions":[{"id":0, "movement":"bomb", "bomb_range":2, "bomb_delay":2}]},
            {"player_id": 1, "turn_number": 7, "actions":[]},
            {"player_id": 2, "turn_number": 7, "actions":[]}
          ]
        }`.parseJSON);
        assertNotThrown(g.doTurn(doTurnMsg, currentWinnerPlayerID, gameState));
        assert(g._characters[0].pos == Position( 2,-1)); // no move action
        assert(g._characters[1].pos == Position(-2, 0)); // no move action
        assert(g._characters[2].pos == Position( 2, 1)); // no move action
        assert( g._characters[0].alive);
        assert(!g._characters[1].alive);
        assert( g._characters[2].alive);
        assert(g._characters[1].reviveDelay == 2);
        assert(g._board.cellAt(Position( 2,-1)).hasBomb); // new bomb
        assert(g._score[0] == 7);
        assert(g._score[1] == 5);
        assert(g._score[2] == 7);

        /+ Eighth turn.
           - Special player moves to Player1's initial location.
        +/
        doTurnMsg = nm.parseDoTurnMessage(`{
          "message_type": "DO_TURN",
          "player_actions": [
            {"player_id": 0, "turn_number": 8, "actions":[{"id":0, "movement":"move", "direction":"y-"}]},
            {"player_id": 1, "turn_number": 8, "actions":[]},
            {"player_id": 2, "turn_number": 8, "actions":[]}
          ]
        }`.parseJSON);
        assertNotThrown(g.doTurn(doTurnMsg, currentWinnerPlayerID, gameState));
        assert(g._characters[0].pos == Position( 1, 0)); // moved
        assert(g._characters[1].pos == Position(-2, 0)); // no move action
        assert(g._characters[2].pos == Position( 2, 1)); // no move action
        assert( g._characters[0].alive);
        assert(!g._characters[1].alive);
        assert( g._characters[2].alive);
        assert(g._characters[1].reviveDelay == 1);
        assert(g._score[0] == 8);
        assert(g._score[1] == 5);
        assert(g._score[2] == 8);

        /+ Ninth turn.
           - Special player drops a bomb so all cells of Player2 are wiped out.
           - Player1 tries to revive but its revive delay has not been reached.
           - Player2 dies.
        +/
        doTurnMsg = nm.parseDoTurnMessage(`{
          "message_type": "DO_TURN",
          "player_actions": [
            {"player_id": 0, "turn_number": 9, "actions":[{"id":0, "movement":"bomb", "bomb_range":2, "bomb_delay":2}]},
            {"player_id": 1, "turn_number": 9, "actions":[{"id":1, "movement":"revive"}]},
            {"player_id": 2, "turn_number": 9, "actions":[]}
          ]
        }`.parseJSON);
        assertNotThrown(g.doTurn(doTurnMsg, currentWinnerPlayerID, gameState));
        assert(g._characters[0].pos == Position( 1, 0)); // no move action
        assert(g._characters[1].pos == Position(-2, 0)); // no move action
        assert(g._characters[2].pos == Position( 2, 1)); // no move action
        assert( g._characters[0].alive);
        assert(!g._characters[1].alive); // Revive failed (revive delay)
        assert(!g._characters[2].alive); // dead!
        assert(!g._board.cellAt(Position( 1, 0)).hasBomb); // no new bomb (it already exploded)
        assert(g._characters[1].reviveDelay == 0);
        assert(g._score[0] == 9);
        assert(g._score[1] == 5);
        assert(g._score[2] == 8); // dead!
        assert(g._cellCount[2] == 0);

        /+ Tenth turn.
           - Player1 still tries to revive, but this is not possible in sudden death.
        +/
        doTurnMsg = nm.parseDoTurnMessage(`{
          "message_type": "DO_TURN",
          "player_actions": [
            {"player_id": 0, "turn_number": 9, "actions":[]},
            {"player_id": 1, "turn_number": 9, "actions":[{"id":1, "movement":"revive"}]},
            {"player_id": 2, "turn_number": 9, "actions":[]}
          ]
        }`.parseJSON);
        assertNotThrown(g.doTurn(doTurnMsg, currentWinnerPlayerID, gameState));
        assert(g._characters[0].pos == Position( 1, 0)); // no move action
        assert(g._characters[1].pos == Position(-2, 0)); // no move action
        assert(g._characters[2].pos == Position( 2, 1)); // no move action
        assert( g._characters[0].alive);
        assert(!g._characters[1].alive); // Revive failed (not allowed in sudden death)
        assert(!g._characters[2].alive);
        assert(g._characters[1].reviveDelay == 0);
        assert(g._score[0] == 10);
        assert(g._score[1] == 5);
        assert(g._score[2] == 8);
    }

    private int determineCurrentWinnerPlayerID()
    {
        import std.typecons;
        alias ScorePid = Tuple!(uint, "score", uint, "playerID");

        auto sortedScores = _score.keys.map!(playerID => ScorePid(_score[playerID], playerID)).array.sort!"a > b";

        if (_isSuddenDeath)
        {
            auto sortedWithoutSpecial = sortedScores.filter!(sp => sp.playerID != 0).array;
            if (sortedWithoutSpecial.length == 0)
                return -1;
            else if (sortedWithoutSpecial.length == 1)
                return sortedWithoutSpecial[0].playerID;
            else if (sortedWithoutSpecial[0].score > sortedWithoutSpecial[1].score)
                return sortedWithoutSpecial[0].playerID;
            else
                return -1;
        }
        else
        {
            if (sortedScores.length == 0)
                return -1;
            else if (sortedScores.length == 1)
                return sortedScores[0].playerID;
            else if (sortedScores[0].score > sortedScores[1].score)
                return sortedScores[0].playerID; // Strictly first
            return -1; // Draw
        }
    }
    unittest
    {
        auto g = generateBasicGame;

        // No player
        g._score.clear;
        assert(g.determineCurrentWinnerPlayerID == -1);

        // Single player
        g._score = [0: 0];
        assert(g.determineCurrentWinnerPlayerID == 0);
        g._score = [0: 42];
        assert(g.determineCurrentWinnerPlayerID == 0);

        // Multiplayer
        g._score = [0:10, 1:10, 2:11];
        assert(g.determineCurrentWinnerPlayerID == 2);
        g._score = [0:20, 1:19, 2:20];
        assert(g.determineCurrentWinnerPlayerID == -1);
        g._score = [0:10, 1:13, 2:5, 3:1, 4:5];
        assert(g.determineCurrentWinnerPlayerID == 1);

        // Sudden death, no player.
        g._isSuddenDeath = true;
        g._score.clear;
        assert(g.determineCurrentWinnerPlayerID == -1);

        // Sudden death, single special player
        g._score = [0:0];
        assert(g.determineCurrentWinnerPlayerID == -1);
        g._score = [0:42];
        assert(g.determineCurrentWinnerPlayerID == -1);

        // Sudden death, single normal player
        g._score = [1:0];
        assert(g.determineCurrentWinnerPlayerID == 1);
        g._score = [1:42];
        assert(g.determineCurrentWinnerPlayerID == 1);

        // Sudden death, special vs normal player
        g._score = [0:0, 1:0];
        assert(g.determineCurrentWinnerPlayerID == 1);
        g._score = [0:42, 1:1];
        assert(g.determineCurrentWinnerPlayerID == 1);

        // Sudden death, special vs several normal players
        g._score = [0:0, 1:0, 2:0];
        assert(g.determineCurrentWinnerPlayerID == -1);
        g._score = [0:42, 1:0, 2:0];
        assert(g.determineCurrentWinnerPlayerID == -1);
        g._score = [0:42, 1:50, 2:50];
        assert(g.determineCurrentWinnerPlayerID == -1);
        g._score = [0:42, 1:51, 2:50];
        assert(g.determineCurrentWinnerPlayerID == 1);
        g._score = [0:42, 1:50, 2:51];
        assert(g.determineCurrentWinnerPlayerID == 2);
        g._score = [0:100, 1:51, 2:50];
        assert(g.determineCurrentWinnerPlayerID == 1);
        g._score = [0:100, 1:50, 2:51];
        assert(g.determineCurrentWinnerPlayerID == 2);
    }

    /// Applies the actions of the players (move characters, drop bombs)...
    private void applyPlayersActions(PlayerActions[] playerActions)
    {
        /+ The actions are applied until convergence,
           in order to allow valid moves that depend on other players.
           As an example, think of adjacent characters that want to move in the
           same direction. They should be able to do it regardless of the order
           of events.
        +/
        alias ActionElement = Tuple!(CharacterActions, "action", uint, "color", bool, "toRemove");

        void doActionRound(ActionElement[] pendingActions)
        {
            bool converged = false;
            do
            {
                foreach (i, ref a; pendingActions)
                {
                    try
                    {
                        if (applyAction(a.action, a.color))
                            a.toRemove = true;
                    }
                    catch(Exception e)
                    {
                        info("Ignoring a character action: ", e.msg);
                        a.toRemove = true;
                    }
                }

                auto remainingActions = pendingActions.remove!"a.toRemove == true";
                converged = remainingActions.length == pendingActions.length;
                pendingActions = remainingActions;
            } while (!converged);
        }

        ActionElement[] actionElements = playerActions.map!(pa=> pa.actions.map!(a => ActionElement(a, pa.color, false))).join;
        doActionRound(actionElements);
    }

    /// Applies a single action on the game. Returns whether this could be done. Throws Exception on error.
    private bool applyAction(in CharacterActions action, in uint color)
    body
    {
        enforce(action.characterID < _characters.length,
            format!"Character id=%s does not exist"(action.characterID));
        auto c = &(_characters[action.characterID]);
        enforce(c.color == color,
            format!"Player with color=%d cannot do actions on character (id=%s, color=%d)"(color, c.id, c.color));

        final switch (action.movement)
        {
            case CharacterMovement.revive:
                enforce(!_isSuddenDeath,
                    format!"Character id=%s cannot be revived (game mode is sudden death)"(c.id));
                enforce(c.alive == false,
                    format!"Character id=%s cannot be revived (already alive)"(c.id));
                enforce(c.reviveDelay == 0,
                    format!"Character id=%s cannot be revived (revive delay is %s)"(c.id, c.reviveDelay));

                auto cell = _board.cellAtOrNull(c.pos);
                assert(cell !is null);

                // Not traversable because of a bomb or a player.
                // This may be invalid because of recent actions from other players.
                // This may become valid after actions from other players in the current turn.
                if (!cell.isTraversable)
                    return false;

                // Everything seems fine. We can revive the player.
                c.alive = true;
                c.reviveDelay = -1;
                cell.addCharacter(c.color);
                return true;

            case CharacterMovement.move:
                enforce(c.alive == true,
                    format!"Character id=%s cannot be moved (not alive)"(c.id));

                auto nextPosition = c.pos + action.direction;
                auto nextCell = _board.cellAtOrNull(nextPosition);
                enforce(nextCell !is null,
                    format!"Character id=%s cannot be moved (no cell at %s)"(c.id, nextPosition));

                // Not traversable because of a bomb or a player.
                // This may be invalid because of recent actions from other players.
                // This may become valid after actions from other players in the current turn.
                if (!nextCell.isTraversable)
                    return false;

                // Everything seems fine. We can move the player.
                _board.cellAt(c.pos).removeCharacter;
                c.pos = nextPosition;
                nextCell.addCharacter(c.color);
                return true;

            case CharacterMovement.bomb:
                enforce(c.alive == true,
                    format!"Character id=%s cannot spawn a bomb (not alive)"(c.id));

                enforce(c.bombCount > 0,
                    format!"Character id=%s cannot spawn a bomb (does not have any bomb)"(c.id));

                auto cell = _board.cellAt(c.pos);
                enforce(!cell.hasBomb,
                    format!"Character id=%s cannot spawn a bomb (cell is already bombed)"(c.id));

                int bombMiniCheck = 2;
                int bombMaxiCheck = 4;
                if (_isSuddenDeath && c.color == 1) // Special players have overpowered bomb range.
                    bombMaxiCheck = 100;

                enforce(action.bombDelay >= bombMiniCheck && action.bombDelay <= bombMaxiCheck,
                    format!"Character id=%s cannot spawn a bomb (invalid bomb delay %s)"(c.id, action.bombDelay));

                enforce(action.bombRange >= bombMiniCheck && action.bombRange <= bombMaxiCheck,
                    format!"Character id=%s cannot spawn a bomb (invalid bomb range %s)"(c.id, action.bombRange));

                /+ Everything seems fine. We can spawn the bomb.

                   bombDelay + 1 is used to minimize players' confusion.
                   This way, a bomb that has just been spawned with delay=2
                   is seen with a delay=2 the first turn the bomb appears
                   (otherwise, would appear with delay=1)
                +/
                if (!_isSuddenDeath || c.color != 1)
                    c.bombCount -= 1;
                cell.addBomb;
                _bombs ~= Bomb(c.pos, c.color, action.bombRange, action.bombDelay + 1);
                return true;
        }
    }
    unittest
    {
        auto g = generateBasicGame;
        CharacterActions a;

        // Initial game alterations
        g._board.removeCell(Position(3,-3));
        g._board.cellAt(Position(1,-3)).addBomb;
        g._bombs ~= Bomb(Position(1,-3), 0, 10, 100);

        // Invalid character
        a.characterID = 42;
        assertThrown(g.applyAction(a, 1));
        assert(collectExceptionMsg(g.applyAction(a, 1)) ==
            `Character id=42 does not exist`);

        // Trying to move opponents' characters
        a.characterID = 0;
        assertThrown(g.applyAction(a, 10));
        assert(collectExceptionMsg(g.applyAction(a, 10)) ==
            `Player with color=10 cannot do actions on character (id=0, color=1)`);

        Character* c = &(g._characters[0]);

        ////////////////
        // Bad revive //
        ////////////////
        // Alive
        a.movement = CharacterMovement.revive;
        assertThrown(g.applyAction(a, 1));
        assert(collectExceptionMsg(g.applyAction(a, 1)) ==
            `Character id=0 cannot be revived (already alive)`);
        // Revive delay has not been reached
        g._board.cellAt(c.pos).removeCharacter;
        c.alive = false;
        c.reviveDelay = 1;
        assertThrown(g.applyAction(a, 1));
        assert(collectExceptionMsg(g.applyAction(a, 1)) ==
            `Character id=0 cannot be revived (revive delay is 1)`);
        // Bad revive position (character on cell)
        c.reviveDelay = 0;
        c.pos = Position(0,1);
        assert(g.applyAction(a, 1) == false);
        // Bad revive position (bomb on cell)
        c.pos = Position(1,-3);
        assert(g.applyAction(a, 1) == false);

        //////////
        // move //
        //////////
        a.movement = CharacterMovement.move;
        // Dead
        assertThrown(g.applyAction(a, 1));
        assert(collectExceptionMsg(g.applyAction(a, 1)) ==
            `Character id=0 cannot be moved (not alive)`);
        // Revive the character
        c.pos = Position(2,-3);
        a.movement = CharacterMovement.revive;
        assert(g.applyAction(a, 1) == true);
        // Out of bounds
        a.movement = CharacterMovement.move;
        a.direction = Direction.Z_PLUS;
        assertThrown(g.applyAction(a, 1));
        assert(collectExceptionMsg(g.applyAction(a, 1)) ==
            `Character id=0 cannot be moved (no cell at {q=2,r=-4})`);
        // Into bomb
        a.direction = Direction.X_MINUS;
        assert(g.applyAction(a, 1) == false);
        // Move next to a character
        a.direction = Direction.Y_MINUS;
        assert(g.applyAction(a, 1) == true);
        assert(g.applyAction(a, 1) == true);
        a.direction = Direction.Z_MINUS;
        assert(g.applyAction(a, 1) == true);
        // Into a character
        assert(g.applyAction(a, 1) == false);

        //////////
        // bomb //
        //////////
        a.movement = CharacterMovement.bomb;
        // Invalid delay
        a.bombRange = 3;
        a.bombDelay = 1;
        assertThrown(g.applyAction(a, 1));
        assert(collectExceptionMsg(g.applyAction(a, 1)) ==
            `Character id=0 cannot spawn a bomb (invalid bomb delay 1)`);
        a.bombDelay = 5;
        assertThrown(g.applyAction(a, 1));
        assert(collectExceptionMsg(g.applyAction(a, 1)) ==
            `Character id=0 cannot spawn a bomb (invalid bomb delay 5)`);
        // Invalid range
        a.bombDelay = 2;
        a.bombRange = 1;
        assertThrown(g.applyAction(a, 1));
        assert(collectExceptionMsg(g.applyAction(a, 1)) ==
            `Character id=0 cannot spawn a bomb (invalid bomb range 1)`);
        a.bombRange = 5;
        assertThrown(g.applyAction(a, 1));
        assert(collectExceptionMsg(g.applyAction(a, 1)) ==
            `Character id=0 cannot spawn a bomb (invalid bomb range 5)`);
        // OK
        a.bombRange = 3;
        a.bombDelay = 2;
        assert(g.applyAction(a, 1) == true);
        // No bomb left
        assertThrown(g.applyAction(a, 1));
        assert(collectExceptionMsg(g.applyAction(a, 1)) ==
            `Character id=0 cannot spawn a bomb (does not have any bomb)`);
        // Onto a bomb
        g._characters[0].bombCount = 1;
        assertThrown(g.applyAction(a, 1));
        assert(collectExceptionMsg(g.applyAction(a, 1)) ==
            `Character id=0 cannot spawn a bomb (cell is already bombed)`);
        // Kill the characters
        assert(c.alive == true);
        g.doBombTurn;
        assert(c.alive == true);
        g.doBombTurn;
        assert(c.alive == true);
        g.doBombTurn;
        assert(c.alive == false);
        // Dead
        assertThrown(g.applyAction(a, 1));
        assert(collectExceptionMsg(g.applyAction(a, 1)) ==
            `Character id=0 cannot spawn a bomb (not alive)`);
    }

    /**
     * Explode bombs, change board colors and kill characters if needed.
    **/
    private void doBombTurn()
    {
        alias ColorDist = Tuple!(uint, "color", int, "distance");
        ColorDist[Position] boardAlterations;
        Bomb[Position] explodedBombs;

        void updateBoardAlterations(ref ColorDist[Position] alterations, in int[Position] explosionRange, in uint color)
        {
            foreach(pos, dist; explosionRange)
            {
                if (pos in alterations)
                {
                    // Potential conflict.
                    if (dist < alterations[pos].distance)
                    {
                        // The new bomb is closer. The cell color is set to the new bomb's.
                        alterations[pos] = ColorDist(color, dist);
                    }
                    else if (dist == alterations[pos].distance)
                    {
                        // At least two bombs are at the same distance of this cell.
                        // If colors are different, reset the cell to a non-player color.
                        if (color != alterations[pos].color)
                            alterations[pos].color = 0;
                    }
                    // Otherwise, the previous bomb(s) were closer, the new bomb can be ignored for this cell.
                }
                else
                {
                    // Newly exploded cell.
                    alterations[pos] = ColorDist(color, dist);
                }
            }
        }

        // Reduce the delay of all bombs.
        // Compute the explosion range of 0-delay bombs
        foreach (ref b; _bombs)
        {
            b.delay = b.delay - 1;

            if (b.delay <= 0)
            {
                explodedBombs[b.position] = b;
                auto explosion = _board.computeExplosionRange(b);
                updateBoardAlterations(boardAlterations, explosion, b.color);
            }
        }

        // Until convergence: Explode bombs that are in exploded cells
        bool converged = false;
        do
        {
            auto newlyExplodedBombs = _bombs.filter!(b => !(b.position in explodedBombs)
                                                       &&  (b.position in boardAlterations));

            foreach (b; newlyExplodedBombs)
            {
                explodedBombs[b.position] = b;
                auto explosion = _board.computeExplosionRange(b);
                updateBoardAlterations(boardAlterations, explosion, b.color);
            }

            converged = newlyExplodedBombs.empty;
        } while(!converged);

        // Kill (non-special) characters on exploded cells.
        auto killedCharacters = _characters.filter!(c =>
            (c.pos in boardAlterations) &&
            (!_isSuddenDeath || c.color != 1));
        foreach (ref c; killedCharacters)
        {
            c.alive = false;
            c.reviveDelay = 3;
        }

        // Remove exploded bombs.
        _bombs = _bombs.remove!(b => b.position in explodedBombs);

        // Update the board
        foreach (pos, colorDist; boardAlterations)
        {
            Cell * cell = _board.cellAt(pos);

            if (_isSuddenDeath && cell.hasCharacter && cell.color == 1)
            {
                // Special players do not die, but bombs on their cell do explode.
                cell.explode(colorDist.color);
                cell.addCharacter(1);
            }
            else
                cell.explode(colorDist.color);
        }
    }
    unittest // One single bomb explodes (kill chars and propagate color)
    {
        auto bombPosition = Position(0,3);
        uint bombColor = 1;
        uint bombRange = 3;

        auto previous = generateBasicGame;
        auto g = generateBasicGame;
        assert(g == previous);

        // Insert bomb
        g._bombs ~= Bomb(bombPosition, bombColor, bombRange, 2);
        g._board.cellAt(bombPosition).addBomb;
        assert(g != previous);

        // First bomb turn (do not explode)
        g.doBombTurn;
        assert(g != previous);
        previous._board.cellAt(bombPosition).addBomb;
        previous._bombs = [Bomb(bombPosition, bombColor, bombRange, 1)];
        assert(g == previous);

        // Second bomb turn (explode)
        g.doBombTurn;
        assert(g != previous);
        previous._bombs = [];
        auto explosion = previous._board.computeExplosionRange(
            Bomb(Position(0,3), bombColor, bombRange, 42));

        foreach (pos; explosion.byKey)
            previous._board.cellAt(pos).explode(bombColor);

        foreach (ref c; previous._characters)
        {
            c.alive = false;
            c.reviveDelay = 3;
        }
        assert(g == previous);

        // Third turn (no bombs: nothing happens)
        g.doBombTurn;
        assert(g == previous);
    }
    unittest // Several bombs (domino effect)
    {
        auto previous = generateBasicGame;
        Game g = generateBasicGame;

        // Set some cells to color 42
        Position[] pos42 = [
            Position(0,0),
            Position(0,1),
            Position(0,2),
            Position(0,3),
            Position(1,2)
        ];
        pos42.each!(pos => g._board.cellAt(pos).explode(42));
        pos42.each!(pos => previous._board.cellAt(pos).explode(42));

        Bomb genBomb(Position pos, uint color)
        {
            return Bomb(pos, color, 10, 10);
        }
        Bomb[] bombs = [
            // Central bomb
            Bomb(Position(0,0), 50, 10, 1),
            // Border bombs
            genBomb(Position( 3, 0), 1),
            genBomb(Position( 3,-3), 2),
            genBomb(Position( 0,-3), 3),
            genBomb(Position(-3, 0), 4),
            genBomb(Position(-3, 3), 5),
            genBomb(Position( 0, 3), 6),
            genBomb(Position( 2, 1), 6),
        ];

        // Insert bombs
        g._bombs = bombs.dup;
        g._bombs.each!(b => g._board.cellAt(b.position).addBomb);
        assert(g != previous);

        previous._bombs = bombs.dup;
        previous._bombs.each!(b => previous._board.cellAt(b.position).addBomb);
        assert(g == previous);

        // First turn (central bomb explode -> all bombs explode)
        g.doBombTurn;
        previous._bombs = [];
        foreach (ref c; previous._characters)
        {
            c.alive = false;
            c.reviveDelay = 3;
        }

        uint[Position] colorAlterations = [
            // Newly central (50)
            Position( 0, 0): 50,
            Position( 1, 0): 50,
            Position( 1,-1): 50,
            Position( 0,-1): 50,
            Position(-1, 0): 50,
            Position(-1, 1): 50,
            Position( 0, 1): 50,
            // Newly 1
            Position( 3, 0): 1,
            Position( 3,-1): 1,
            // Newly 2
            Position( 3,-3): 2,
            Position( 3,-2): 2,
            Position( 2,-2): 2,
            Position( 2,-3): 2,
            // Newly 3
            Position( 0,-3): 3,
            Position( 1,-3): 3,
            Position( 0,-2): 3,
            Position(-1,-2): 3,
            // Newly 4
            Position(-3, 0): 4,
            Position(-2,-1): 4,
            Position(-2, 0): 4,
            Position(-3, 1): 4,
            // Newly 5
            Position(-3, 3): 5,
            Position(-3, 2): 5,
            Position(-2, 2): 5,
            Position(-2, 3): 5,
            // Newly 6 ( 0, 3)
            Position( 0, 3): 6,
            Position(-1, 3): 6,
            Position( 0, 2): 6,
            Position( 1, 2): 6, // shared with bomb( 2, 1) of same color
            // Newly 6 ( 2, 1)
            Position( 2, 1): 6,
            Position( 1, 1): 6,
            Position(-2, 1): 6,
            Position( 2,-1): 6,
            // Newly neutral
            Position( 2, 0): 0, // (3,0), (2,1)
        ];
        colorAlterations.each!((pos, color) => previous._board.cellAt(pos).explode(color));
        assert(g == previous);

        // Second turn (does nothing)
        g.doBombTurn;
        assert(g == previous);
    }
    unittest // Two bombs (NO domino effect)
    {
        auto previous = generateBasicGame;
        auto g = generateBasicGame;

        // Insert bombs
        Bomb[] bombs = [
            Bomb(Position(-3, 0), 1, 3, 1),
            Bomb(Position(1, 0), 2, 4, 2),
        ];

        // Insert bombs
        g._bombs = bombs.dup;
        g._bombs.each!(b => g._board.cellAt(b.position).addBomb);
        assert(g != previous);

        previous._bombs = bombs.dup;
        previous._bombs.each!(b => previous._board.cellAt(b.position).addBomb);
        assert(g == previous);

        // First turn. Bomb explodes alone (kills first character).
        g.doBombTurn;
        assert(g != previous);

        foreach (pos; previous._board.computeExplosionRange(bombs[0]).byKey)
        {
            previous._board.cellAt(pos).explode(bombs[0].color);
        }
        previous._bombs = bombs[1..$];
        previous._bombs[0].delay = 1;
        previous._characters[0].alive = false;
        previous._characters[0].reviveDelay = 3;
        assert(g == previous);

        // Second turn. Bomb explodes alone (recovers all cells, kills c2)
        g.doBombTurn;
        assert(g != previous);

        foreach (pos; previous._board.computeExplosionRange(bombs[1]).byKey)
        {
            previous._board.cellAt(pos).explode(bombs[1].color);
        }
        previous._bombs = [];
        previous._characters[1].alive = false;
        previous._characters[1].reviveDelay = 3;
        assert(g == previous);

        // Third turn. Does nothing.
        g.doBombTurn;
        assert(g == previous);
    }

    // Reduce the revive delay of dead characters.
    private void doDeadCharacterTurn()
    {
        auto deadCharacters = _characters.filter!(c => c.alive == false);
        deadCharacters.each!((ref c) => c.reviveDelay = max(0, c.reviveDelay - 1));
    }
    unittest
    {
        auto g = generateBasicGame;

        // Initial state.
        assert(g._characters[0].alive == true);
        assert(g._characters[0].reviveDelay == -1);
        assert(g._characters[1].alive == true);
        assert(g._characters[1].reviveDelay == -1);

        // Kill character 0.
        g._characters[0].alive = false;
        g._characters[0].reviveDelay = 2;

        // Turn 1.
        g.doDeadCharacterTurn;
        assert(g._characters[0].alive == false);
        assert(g._characters[0].reviveDelay == 1);
        assert(g._characters[1].alive == true);
        assert(g._characters[1].reviveDelay == -1);

        // Turn 2.
        g.doDeadCharacterTurn;
        assert(g._characters[0].alive == false);
        assert(g._characters[0].reviveDelay == 0);
        assert(g._characters[1].alive == true);
        assert(g._characters[1].reviveDelay == -1);

        // Turn 3.
        g.doDeadCharacterTurn;
        assert(g._characters[0].alive == false);
        assert(g._characters[0].reviveDelay == 0);
        assert(g._characters[1].alive == true);
        assert(g._characters[1].reviveDelay == -1);
    }

    // Increase the bomb count of characters every 10 turns (max bombCount : 2)
    private void updateCharactersBombCount()
    {
        if (_turnNumber % 10 == 0)
        {
            _characters.each!((ref c) => c.bombCount = min(2, c.bombCount + 1));
        }
    }
    unittest
    {
        auto g = generateBasicGame;

        // Initial state.
        assert(g._characters[0].bombCount == 1);
        assert(g._characters[1].bombCount == 1);

        // Should not change during 9 turns.
        foreach(i; 1 .. 10)
        {
            g._turnNumber += 1;
            g.updateCharactersBombCount;
            assert(g._characters[0].bombCount == 1);
            assert(g._characters[1].bombCount == 1);
        }

        // 10th turn should increase the bomb count.
        g._turnNumber += 1;
        g.updateCharactersBombCount;
        assert(g._characters[0].bombCount == 2);
        assert(g._characters[1].bombCount == 2);

        // Should not change now
        foreach(i; 0..100)
        {
            g._turnNumber += 1;
            g.updateCharactersBombCount;
            assert(g._characters[0].bombCount == 2);
            assert(g._characters[1].bombCount == 2);
        }
    }

    override bool opEquals(const Object o) const
    {
        auto g = cast(const Game) o;
        return (this._board == g._board) &&
               (this._bombs == g._bombs) &&
               (this._characters == g._characters) &&
               (this._initialPositions == g._initialPositions);
    }

    override string toString()
    {
        // Explicitly sort the data for deterministic prints
        import std.algorithm;
        import std.array;

        return format!"{bombs=%s, characters=%s, initialPositions=[%s], board=%s}"(
            _bombs.sort!"a.position < b.position",
            _characters,
            _initialPositions.keys.map!(color => format!"%s:%s"(color, _initialPositions[color].sort)).join(", "),
            _board.toString
        );
    }
    unittest
    {
        auto g = new Game(`{
          "cells":[
            {"q":0,"r":0},
            {"q":0,"r":1}
          ],
          "initial_positions":{
            "0": [{"q":0, "r":0}],
            "1": [{"q":0, "r":1}]
          }
        }`.parseJSON);
        assert(g.toString == `{bombs=[], characters=[], initialPositions=[0:[{q=0,r=0}], 1:[{q=0,r=1}]], board={cells:[{q=0,r=0}:{color=0}, {q=0,r=1}:{color=0}], neighbors:[{q=0,r=0}:[{q=0,r=1}], {q=0,r=1}:[{q=0,r=0}]]}}`);

        g.placeInitialCharacters(2);
        assert(g.toString == `{bombs=[], characters=[Character(0, 1, true, -1, 1, {q=0,r=0}), Character(1, 2, true, -1, 1, {q=0,r=1})], initialPositions=[0:[{q=0,r=0}], 1:[{q=0,r=1}]], board={cells:[{q=0,r=0}:{color=1,char}, {q=0,r=1}:{color=2,char}], neighbors:[{q=0,r=0}:[{q=0,r=1}], {q=0,r=1}:[{q=0,r=0}]]}}`);

        g._bombs = [Bomb(Position(0,0), 1, 1, 1)];
        g._board.cellAt(Position(0,0)).addBomb;
        assert(g.toString == `{bombs=[Bomb({q=0,r=0}, 1, 1, 1)], characters=[Character(0, 1, true, -1, 1, {q=0,r=0}), Character(1, 2, true, -1, 1, {q=0,r=1})], initialPositions=[0:[{q=0,r=0}], 1:[{q=0,r=1}]], board={cells:[{q=0,r=0}:{color=1,char,bomb}, {q=0,r=1}:{color=2,char}], neighbors:[{q=0,r=0}:[{q=0,r=1}], {q=0,r=1}:[{q=0,r=0}]]}}`);
    }
}

private Game generateBasicGame()
{
    auto g = new Game(`{
      "cells":[
        {"q":-3,"r":0},
        {"q":-3,"r":1},
        {"q":-3,"r":2},
        {"q":-3,"r":3},
        {"q":-2,"r":-1},
        {"q":-2,"r":0},
        {"q":-2,"r":1},
        {"q":-2,"r":2},
        {"q":-2,"r":3},
        {"q":-1,"r":-2},
        {"q":-1,"r":-1},
        {"q":-1,"r":0},
        {"q":-1,"r":1},
        {"q":-1,"r":2},
        {"q":-1,"r":3},
        {"q":0,"r":-3},
        {"q":0,"r":-2},
        {"q":0,"r":-1},
        {"q":0,"r":0},
        {"q":0,"r":1},
        {"q":0,"r":2},
        {"q":0,"r":3},
        {"q":1,"r":-3},
        {"q":1,"r":-2},
        {"q":1,"r":-1},
        {"q":1,"r":0},
        {"q":1,"r":1},
        {"q":1,"r":2},
        {"q":2,"r":-3},
        {"q":2,"r":-2},
        {"q":2,"r":-1},
        {"q":2,"r":0},
        {"q":2,"r":1},
        {"q":3,"r":-3},
        {"q":3,"r":-2},
        {"q":3,"r":-1},
        {"q":3,"r":0}],
      "initial_positions":{
        "0": [{"q":0, "r":0}],
        "1": [{"q":0, "r":1}]
      }
    }`.parseJSON);

    g.initializeGame(2, 0);
    return g;
}

private Game generateSuddenDeathGame()
{
    auto g = new Game(`{
      "cells":[
        {"q":-3,"r":0},
        {"q":-3,"r":1},
        {"q":-3,"r":2},
        {"q":-3,"r":3},
        {"q":-2,"r":-1},
        {"q":-2,"r":0},
        {"q":-2,"r":1},
        {"q":-2,"r":2},
        {"q":-2,"r":3},
        {"q":-1,"r":-2},
        {"q":-1,"r":-1},
        {"q":-1,"r":0},
        {"q":-1,"r":1},
        {"q":-1,"r":2},
        {"q":-1,"r":3},
        {"q":0,"r":-3},
        {"q":0,"r":-2},
        {"q":0,"r":-1},
        {"q":0,"r":0},
        {"q":0,"r":1},
        {"q":0,"r":2},
        {"q":0,"r":3},
        {"q":1,"r":-3},
        {"q":1,"r":-2},
        {"q":1,"r":-1},
        {"q":1,"r":0},
        {"q":1,"r":1},
        {"q":1,"r":2},
        {"q":2,"r":-3},
        {"q":2,"r":-2},
        {"q":2,"r":-1},
        {"q":2,"r":0},
        {"q":2,"r":1},
        {"q":3,"r":-3},
        {"q":3,"r":-2},
        {"q":3,"r":-1},
        {"q":3,"r":0}],
      "initial_positions":{
        "0": [{"q":-1, "r": 0}],
        "1": [{"q": 1, "r": 0}]
      },
      "special_initial_positions":[{"q":0, "r":0}]
    }`.parseJSON);

    g.initializeGame(2, 1);
    return g;
}
