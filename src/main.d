import std.json;
import std.format;
import std.stdio;

import game;
import netorcai;

void main()
{
    auto game = new Game(`{
      "cells":[
        {"q":-3,"r":0,"wall":false},
        {"q":-3,"r":1,"wall":false},
        {"q":-3,"r":2,"wall":false},
        {"q":-3,"r":3,"wall":false},
        {"q":-2,"r":-1,"wall":false},
        {"q":-2,"r":0,"wall":false},
        {"q":-2,"r":1,"wall":false},
        {"q":-2,"r":2,"wall":false},
        {"q":-2,"r":3,"wall":false},
        {"q":-1,"r":-2,"wall":false},
        {"q":-1,"r":-1,"wall":false},
        {"q":-1,"r":0,"wall":false},
        {"q":-1,"r":1,"wall":false},
        {"q":-1,"r":2,"wall":false},
        {"q":-1,"r":3,"wall":false},
        {"q":0,"r":-3,"wall":false},
        {"q":0,"r":-2,"wall":false},
        {"q":0,"r":-1,"wall":false},
        {"q":0,"r":0,"wall":false},
        {"q":0,"r":1,"wall":false},
        {"q":0,"r":2,"wall":false},
        {"q":0,"r":3,"wall":false},
        {"q":1,"r":-3,"wall":false},
        {"q":1,"r":-2,"wall":false},
        {"q":1,"r":-1,"wall":false},
        {"q":1,"r":0,"wall":false},
        {"q":1,"r":1,"wall":false},
        {"q":1,"r":2,"wall":false},
        {"q":2,"r":-3,"wall":false},
        {"q":2,"r":-2,"wall":false},
        {"q":2,"r":-1,"wall":false},
        {"q":2,"r":0,"wall":false},
        {"q":2,"r":1,"wall":false},
        {"q":3,"r":-3,"wall":false},
        {"q":3,"r":-2,"wall":false},
        {"q":3,"r":-1,"wall":false},
        {"q":3,"r":0,"wall":false}],
      "initial_positions":{
        "0": [{"q":0, "r":0}],
        "1": [{"q":0, "r":1}]
      }
    }`.parseJSON);

	auto c = new Client;
    scope(exit) c.destroy();
    write("Connecting to netorcai... "); stdout.flush();
    c.connect();
    writeln("done");

    write("Logging in as a game logic... "); stdout.flush();
    c.sendLogin("hexabomb", "game logic");
    c.readLoginAck();
    writeln("done");

    write("Waiting for DO_INIT... "); stdout.flush();
    auto doInit = c.readDoInit();
    writeln("done");

    game.initializeGame(doInit.nbPlayers);
    JSONValue doInitAck = `{}`.parseJSON;
    doInitAck["all_clients"] = game.describeInitialState;
    c.sendDoInitAck(doInitAck);

    foreach (turn; 0..doInit.nbTurnsMax)
    {
        write(format!"Waiting for DO_TURN %d... "(turn)); stdout.flush();
        auto doTurn = c.readDoTurn();
        writeln("done");

        JSONValue gameState;
        int currentWinner;
        game.doTurn(doTurn, currentWinner, gameState);

        JSONValue nGameState = `{}`.parseJSON;
        nGameState["all_clients"] = gameState;
        c.sendDoTurnAck(nGameState, currentWinner);
    }
}
