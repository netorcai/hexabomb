#!/usr/bin/env python3
from netorcai.client import Client
from hexabomb import *
import random
import sys

def main():
    try:
        client = Client()

        print("Connecting to netorcai...", end=' ', flush=True)
        client.connect()
        print("done")

        print("Logging in as a player...", end=' ', flush=True)
        client.send_login("py-player", "player")
        client.read_login_ack()
        print("done")

        print("Waiting for GAME_STARTS...", end=' ', flush=True)
        game_starts = client.read_game_starts()
        game_state = GameState(game_starts.initial_game_state)
        my_color = game_starts.player_id + 1
        print("done")

        possible_actions = [
            {"movement":"move", "direction":"x+"},
            {"movement":"move", "direction":"y+"},
            {"movement":"move", "direction":"z+"},
            {"movement":"move", "direction":"x-"},
            {"movement":"move", "direction":"y-"},
            {"movement":"move", "direction":"z-"},
            {"movement":"bomb", "bomb_delay":3, "bomb_range":3},
            {"movement":"revive"}
        ]

        for i in range(game_starts.nb_turns_max):
            print("Waiting for TURN...", end=' ', flush=True)
            turn = client.read_turn()
            game_state = GameState(turn.game_state)
            print("done")

            # Take a random action for each character of the bot.
            actions = []
            for character in game_state.characters:
                if character.color == my_color:
                    action = random.choice(possible_actions)
                    action["id"] = character.id
                    actions.append(action)

            print("Sending actions {}...".format(actions), end=' ', flush=True)
            client.send_turn_ack(turn.turn_number, actions)
            print("done")
    except Exception as e:
        print(e)
        sys.exit(1)
    sys.exit(0)

if __name__ == '__main__':
    main()
