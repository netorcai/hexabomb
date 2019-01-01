#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include <vector>
#include <string>

#include <boost/algorithm/string/join.hpp>
#include <boost/algorithm/string/replace.hpp>

#include <netorcai-client-cpp/client.hpp>
#include <netorcai-client-cpp/error.hpp>

#include "hexabomb-parse.hpp"

int main()
{
    srand(time(0));

    using namespace netorcai;
    using namespace std;

    try
    {
        Client c;

        printf("Connecting to netorcai... "); fflush(stdout);
        c.connect();
        printf("done\n");

        printf("Logging in as a player... "); fflush(stdout);
        c.sendLogin("C++-player", "player");
        c.readLoginAck();
        printf("done\n");

        std::unordered_map<Coordinates, Cell> cells;
        std::vector<Character> characters;
        std::vector<Bomb> bombs;
        std::map<int, int> score, cellCount;

        printf("Waiting for GAME_STARTS... "); fflush(stdout);
        const GameStartsMessage gameStarts = c.readGameStarts();
        parseGameState(gameStarts.initialGameState, cells, characters, bombs, score, cellCount);
        int myColor = gameStarts.playerID + 1;
        printf("done\n");

        const vector<string> possibleActions = {
            R"({"id":ID, "movement":"move", "direction":"x+"})",
            R"({"id":ID, "movement":"move", "direction":"y+"})",
            R"({"id":ID, "movement":"move", "direction":"z+"})",
            R"({"id":ID, "movement":"move", "direction":"x-"})",
            R"({"id":ID, "movement":"move", "direction":"y-"})",
            R"({"id":ID, "movement":"move", "direction":"z-"})",
            R"({"id":ID, "movement":"bomb", "bomb_delay":3, "bomb_range":3})",
            R"({"id":ID, "movement":"revive", "revive_q":0, "revive_r":0})",
        };

        for (int i = 1; i < gameStarts.nbTurnsMax; i++)
        {
            printf("Waiting for TURN... "); fflush(stdout);
            const TurnMessage turn = c.readTurn();
            parseGameState(turn.gameState, cells, characters, bombs, score, cellCount);
            printf("done\n");

            // Take a random action for each character of the bot.
            vector<string> actions;
            for (const auto & character : characters)
            {
                if (character.color == myColor)
                {
                    // Pick a random action.
                    string action = possibleActions[rand()%possibleActions.size()];

                    // Replace ID by the character ID. Yup, still not in C++ standard lib...
                    boost::replace_all(action, "ID", to_string(character.id));
                    actions.push_back(action);
                }
            }

            string mergedActions = "[" + boost::join(actions, ", ") + "]";
            printf("Sending actions=%s... ", mergedActions.c_str()); fflush(stdout);
            c.sendTurnAck(turn.turnNumber, json::parse(mergedActions));
            printf("done\n");
        }

        return 0;
    }
    catch (const netorcai::Error & e)
    {
        printf("Failure: %s\n", e.what());
        return 1;
    }
}
