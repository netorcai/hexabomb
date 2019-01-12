import std.algorithm;
import std.conv;
import std.json;
import std.format;
import std.random;
import std.stdio;
import std.string;

import netorcai;

import hexabomb_parse;

void main()
{
    try
    {
        auto c = new Client;

        write("Connecting to netorcai... "); stdout.flush();
        c.connect();
        writeln("done");

        write("Logging in as a player... "); stdout.flush();
        c.sendLogin("random-D", "player");
        c.readLoginAck();
        writeln("done");

        Cell[Coordinates] cells;
        Character[] characters;
        Bomb[] bombs;
        int[int] score;
        int[int] cellCount;

        string[] possibleActions = [
            `{"id":ID, "movement":"move", "direction":"x+"}`,
            `{"id":ID, "movement":"move", "direction":"y+"}`,
            `{"id":ID, "movement":"move", "direction":"z+"}`,
            `{"id":ID, "movement":"move", "direction":"x-"}`,
            `{"id":ID, "movement":"move", "direction":"y-"}`,
            `{"id":ID, "movement":"move", "direction":"z-"}`,
            `{"id":ID, "movement":"bomb", "bomb_delay":3, "bomb_range":3}`,
            `{"id":ID, "movement":"revive"}`,
        ];
        writeln("possibleActions:", possibleActions);

        write("Waiting for GAME_STARTS... "); stdout.flush();
        const auto gameStarts = c.readGameStarts();
        parseGameState(gameStarts.initialGameState, cells, characters, bombs, score, cellCount);
        int myColor = gameStarts.playerID + 1;
        writeln("done");

        foreach (i; 1..gameStarts.nbTurnsMax)
        {
            write("Waiting for TURN... "); stdout.flush();
            const auto turn = c.readTurn();
            writeln("done");
            parseGameState(turn.gameState, cells, characters, bombs, score, cellCount);

            // Take a random action for each character of the bot.
            string[] actions;
            foreach (myCharacter; characters.filter!(c => c.color == myColor))
            {
                actions ~= possibleActions.choice.replace("ID", to!string(myCharacter.id));
            }
            writeln(actions);

            string mergedActions = format!"[%s]"(actions.join(","));
            write(format!"Sending actions=%s... "(mergedActions)); stdout.flush();
            c.sendTurnAck(turn.turnNumber, mergedActions.parseJSON);
            writeln("done");
        }

        write("Waiting for GAME_ENDS... "); stdout.flush();
        auto gameEnds = c.readGameEnds();
        writeln("done");
    }
    catch(Exception e)
    {
        writeln("Failure: ", e.msg);
    }
}
