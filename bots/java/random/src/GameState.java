package org.hexabomb;

import java.util.*;
import org.json.*;

public class GameState
{
    public HashMap<Coordinates, Cell> cells;
    public ArrayList<Character> characters;
    public ArrayList<Bomb> bombs;
    public HashMap<Integer, Integer> score;
    public HashMap<Integer, Integer> cellCount;

    public static HashMap<Integer, Integer> parseIntIntMap(JSONObject o)
    {
        HashMap<Integer, Integer> m = new HashMap<Integer, Integer>();

        for(Iterator iterator = o.keySet().iterator(); iterator.hasNext();)
        {
            String key = (String) iterator.next();
            int value = o.getInt(key);

            m.put(Integer.parseInt(key), value);
        }

        return m;
    }

    public static GameState parse(JSONObject o)
    {
        GameState gs = new GameState();
        gs.cells = Cell.parse(o.getJSONArray("cells"));
        gs.characters = Character.parse(o.getJSONArray("characters"));
        gs.bombs = Bomb.parse(o.getJSONArray("bombs"));
        gs.score = parseIntIntMap(o.getJSONObject("score"));
        gs.cellCount = parseIntIntMap(o.getJSONObject("cell_count"));

        return gs;
    }
}
