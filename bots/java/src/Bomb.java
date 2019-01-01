package org.hexabomb;

import java.util.*;
import org.json.*;

public class Bomb
{
    Coordinates coord;
    int color;
    int range;
    int delay;

    public static Bomb parse(JSONObject o)
    {
        Bomb b = new Bomb();
        b.coord = new Coordinates();
        b.coord.q = o.getInt("q");
        b.coord.r = o.getInt("r");
        b.color = o.getInt("color");
        b.range = o.getInt("range");
        b.delay = o.getInt("delay");

        return b;
    }

    public static ArrayList<Bomb> parse(JSONArray a)
    {
        ArrayList<Bomb> arr = new ArrayList<Bomb>();
        for (int i = 0; i < a.length(); i++)
        {
            arr.add(Bomb.parse(a.getJSONObject(i)));
        }

        return arr;
    }
}
