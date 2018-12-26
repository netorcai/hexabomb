package org.hexabomb.bot;

import java.util.*;
import org.json.*;
import org.netorcai.Client;
import org.netorcai.message.*;
import org.hexabomb.*;

public class Random
{
    public static String getRandomElement(ArrayList<String> arr)
    {
        java.util.Random rand = new java.util.Random();
        return arr.get(rand.nextInt(arr.size()));
    }

    public static void main(String [] args)
    {
        try
        {
            Client c = new Client();

            System.out.printf("Connecting to netorcai... ");
            System.out.flush();
            c.connect();
            System.out.println("done");

            System.out.printf("Logging in as a player... ");
            System.out.flush();
            c.sendLogin("java", "player");
            c.readLoginAck();
            System.out.println("done");

            System.out.printf("Waiting for GAME_STARTS... ");
            System.out.flush();
            GameStartsMessage gameStarts = c.readGameStarts();
            GameState initialGameState = GameState.parse(gameStarts.initialGameState);
            int myColor = gameStarts.playerID + 1;
            System.out.println("done");

            ArrayList<String> possibleActions = new ArrayList<String>();
            possibleActions.add("{\"id\":ID, \"movement\":\"move\", \"direction\":\"x+\"}");
            possibleActions.add("{\"id\":ID, \"movement\":\"move\", \"direction\":\"y+\"}");
            possibleActions.add("{\"id\":ID, \"movement\":\"move\", \"direction\":\"z+\"}");
            possibleActions.add("{\"id\":ID, \"movement\":\"move\", \"direction\":\"x-\"}");
            possibleActions.add("{\"id\":ID, \"movement\":\"move\", \"direction\":\"y-\"}");
            possibleActions.add("{\"id\":ID, \"movement\":\"move\", \"direction\":\"z-\"}");
            possibleActions.add("{\"id\":ID, \"movement\":\"bomb\", \"bomb_delay\":3, \"bomb_range\":3}");
            possibleActions.add("{\"id\":ID, \"movement\":\"revive\", \"revive_q\":0, \"revive_r\":0}");

            for (int i = 1; i < gameStarts.nbTurnsMax; i++)
            {
                System.out.printf("Waiting for TURN... ");
                System.out.flush();
                TurnMessage turn = c.readTurn();
                GameState gameState = GameState.parse(turn.gameState);
                System.out.println("done");

                // Take a random action for each character of the bot.
                ArrayList<String> actions = new ArrayList<String>();
                for (int j = 0; j < gameState.characters.size(); j++)
                {
                    org.hexabomb.Character character = gameState.characters.get(j);
                    if (character.color == myColor)
                    {
                        // Pick a random action.
                        String action = getRandomElement(possibleActions);

                        // Replace ID by the character ID.
                        action = action.replace("ID", String.valueOf(character.id));
                        actions.add(action);
                    }
                }

                String mergedActions = "[" + String.join(", ", actions) + "]";
                System.out.format("Sending actions=%s... ", mergedActions);
                c.sendTurnAck(turn.turnNumber,  new JSONArray(mergedActions));
                System.out.println("done");
            }
        }
        catch(Throwable t)
        {
            System.out.println(t);
        }
    }
}
