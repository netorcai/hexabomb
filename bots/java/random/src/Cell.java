package org.hexabomb;

import java.util.*;
import org.json.*;

public class Cell
{
    Coordinates coord;
    int color;

    public static Cell parse(JSONObject o)
    {
        Cell c = new Cell();
        c.coord = new Coordinates();
        c.coord.q = o.getInt("q");
        c.coord.r = o.getInt("r");
        c.color = o.getInt("color");

        return c;
    }

    public static HashMap<Coordinates, Cell> parse(JSONArray a)
    {
        HashMap<Coordinates, Cell> arr = new HashMap<Coordinates, Cell>();
        for (int i = 0; i < a.length(); i++)
        {
            Cell c = Cell.parse(a.getJSONObject(i));
            arr.put(c.coord, c);
        }

        return arr;
    }
}
