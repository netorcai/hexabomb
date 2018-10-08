from hexagon access *;
from player access *;
from bomb access *;
from palette access palette3;

// Variables
int turn = 0;
bool draw_player1 = true;
bool draw_bomb = true;
bool highlight_cells = true;

// Array of cells to plot
Hexagon[] hexes = {
    Hex(0 , 0, palette3[0]),

    Hex(0 ,-1),
    Hex(0 ,-2),
    Hex(-1, 0, palette3[0]),
    Hex(-2, 0, palette3[0]),
    Hex(-1, 1, palette3[0]),
    Hex(-2, 2),
    Hex( 0, 1),
    Hex(1 , 0),
    Hex(2 , 0),

    Hex(2 ,-2),
    Hex(-1,-1),
    Hex(-2, 1, palette3[0]),
    Hex(-1, 2),
    Hex( 1, 1),
    Hex( 2,-1),
    Hex( 1,-2),

    Hex(-3, 0, palette3[0]),
    Hex(-2,-1),
    Hex(-1,-2),
    Hex( 0,-3, palette3[1]),
    Hex( 1,-3),
    Hex( 2,-3, palette3[1]),
    Hex( 3,-3),
    Hex( 3,-2),
    Hex( 3,-1),
    Hex( 3, 0),
    Hex( 2, 1),
    Hex( 1, 2),
    Hex( 0, 3),
    Hex(-1, 3),
    Hex(-2, 3),
    Hex(-3, 3, palette3[1]),
    Hex(-3, 2),
    Hex(-3, 1, palette3[0]),

    Hex( 0, 2, gray(0.1)),
    Hex(1 ,-1, gray(0.1))
};

// Array of bombs
Bomb[] bombs = {
    Bomb.Bomb(Hex( 0, 0), graphic("fat_bomb.eps", "width=14mm"), 2),
    Bomb.Bomb(Hex(-3, 3), graphic("fat_bomb.eps", "width=14mm"), 2),
    Bomb.Bomb(Hex(-3, 0), graphic("thin_bomb.eps", "width=8mm"), 2),
    Bomb.Bomb(Hex( 0,-3), graphic("thin_bomb.eps", "width=8mm"), 2),
    Bomb.Bomb(Hex( 2,-3), graphic("thin_bomb.eps", "width=8mm"), 2)
};

bool should_display_coordinates(Hexagon hex)
{
    if (hex.fill_color == gray(0.1))
        return false;

    if (turn > 1)
        return true;

    for (Bomb b : bombs)
    {
        if (coordinates_equals(b.hex, hex))
            return false;
    }

    return true;
}

bool should_highlight_coordinates(Hexagon hex)
{
    if (coordinates_equals(hex, Hex(-2, 1)))
        return true;
    if (coordinates_equals(hex, Hex(-1, 2)))
        return true;
    if (coordinates_equals(hex, Hex( 2,-1)))
        return true;
    if (coordinates_equals(hex, Hex( 1,-3)))
        return true;

    return false;
}

void render(string filename)
{
    save();

    // Draw the hexagons
    for (Hexagon hex : hexes)
    {
        hex.draw(draw_coordinates=should_display_coordinates(hex));
    }

    if (highlight_cells)
    {
        for (Hexagon hex : hexes)
        {
            if (should_highlight_coordinates(hex))
            {
                hex.border_color = orange + linewidth(3);
                hex.draw(draw_coordinates=should_display_coordinates(hex));
                hex.border_color = black;
            }
        }
    }

    // Draw the bombs
    if (draw_bomb)
    {
        for (Bomb bomb : bombs)
        {
            bomb.draw(draw_delay=true);
        }
    }

    shipout(filename);
    restore();
}

void doTurn()
{
    turn = turn + 1;

    if (turn == 1)
    {
        for (Bomb bomb : bombs)
        {
            bomb.delay = 1;
        }
    }
    else if (turn == 2)
    {
        draw_bomb = false;

        // Fat blue bomb at ( 0, 0)
        hexes[1].fill_color = palette3[0];
        hexes[7].fill_color = palette3[0];
        hexes[8].fill_color = palette3[0];
        hexes[9].fill_color = palette3[0];
        hexes[11].fill_color = palette3[0];
        hexes[14].fill_color = palette3[0];

        // Fat green bomb at (-3, 3)
        hexes[6].fill_color = palette3[1];
        hexes[30].fill_color = palette3[1];
        hexes[31].fill_color = palette3[1];
        hexes[33].fill_color = palette3[1];

        // Thin blue bomb at (-3, 0)
        hexes[18].fill_color = palette3[0];

        // Thin green bomb at ( 0,-3)
        hexes[2].fill_color = palette3[1];
        hexes[19].fill_color = palette3[1];
        hexes[21].fill_color = palette3[1];

        // Thin green bomb at ( 2,-3)
        hexes[10].fill_color = palette3[1];
        hexes[16].fill_color = palette3[1];
        hexes[23].fill_color = palette3[1];

        // Newly neutral
        hexes[12].fill_color = white;

        highlight_cells = true;
    }
}

render("explosion_simultaneous_turn" + string(turn));

doTurn();
render("explosion_simultaneous_turn" + string(turn));

doTurn();
render("explosion_simultaneous_turn" + string(turn));

doTurn();
render("explosion_simultaneous_turn" + string(turn));
