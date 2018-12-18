import std.conv;
import std.json;
import std.format;
import std.stdio;

import docopt;

import game;
import netorcai;

/// Parse main arguments. The game loop is in the doGame function.
int main(string[] args)
{
    auto doc = `hexabomb — D game server

Usage:
  hexabomb <map> [options]
  hexabomb --help

Options:
  --help                        show this help
  -h <host>, --hostname <host>  set netorcai's hostname [default: 127.0.0.1]
  -p <port>, --port <port>      set netorcai's port [default: 4242]`;

    // Read arguments
    auto arguments = docopt.docopt(doc, args[1..$], true);
    string map = arguments["<map>"].toString;
    string hostname = arguments["--hostname"].toString;
    ushort port;

    try
    {
        port = to!ushort(arguments["--port"].toString);
    }
    catch (Exception e)
    {
        writeln("Invalid port: ", e.msg);
        return 1;
    }

    // Launch the game
    try
    {
        doGame(map, hostname, port);
        return 0;
    }
    catch (Exception e)
    {
        writeln(e.msg);
        return 1;
    }
}

/// Create a Game from a file map. Throw Exception on error
Game gameFromFile(in string mapFilename)
{
    import std.exception : enforce;
    import std.file;

    enforce(mapFilename.exists, format!"File %s does not exist"(mapFilename));
    enforce(mapFilename.isFile, format!"%s is not a file"(mapFilename));
    string fileContent = mapFilename.readText;
    JSONValue fileContentJSON;
    try
    {
        fileContentJSON = fileContent.parseJSON;
    }
    catch (Exception e)
    {
        throw new Exception(format!"Invalid JSON: %s"(e.msg));
    }

    return new Game(fileContentJSON);
}

/// "Main" game function
void doGame(in string mapFilename, in string hostname, in ushort port)
{
    write(format!"Loading map %s... "(mapFilename)); stdout.flush();
    auto game = gameFromFile(mapFilename);
    writeln("done");

	auto c = new Client;
    write("Connecting to netorcai... "); stdout.flush();
    c.connect(hostname, port);
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
    doInitAck["all_clients"] = game.describeState;
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
