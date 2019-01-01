package org.hexabomb;

import java.util.*;
import org.json.*;

public class Character
{
    public int id;
    public Coordinates coord;
    public int color;
    public boolean isAlive;
    public int reviveDelay;

    public static Character parse(JSONObject o)
    {
        Character b = new Character();
        b.id = o.getInt("id");
        b.coord = new Coordinates();
        b.coord.q = o.getInt("q");
        b.coord.r = o.getInt("r");
        b.color = o.getInt("color");
        b.isAlive = o.getBoolean("alive");
        b.reviveDelay = o.getInt("revive_delay");

        return b;
    }

    public static ArrayList<Character> parse(JSONArray a)
    {
        ArrayList<Character> arr = new ArrayList<Character>();
        for (int i = 0; i < a.length(); i++)
        {
            Character c = Character.parse(a.getJSONObject(i));
            arr.add(c);
        }

        return arr;
    }
}
