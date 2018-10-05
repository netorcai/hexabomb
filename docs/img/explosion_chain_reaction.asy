from hexagon access *;
from player access *;
from bomb access *;
from palette access palette3;

// Variables
int turn = 0;
bool draw_player1 = true;
bool draw_bomb = true;
bool highlight_cells = true;
Hexagon coordinates_to_highlight = Hex(42,42);

// Array of cells to plot
Hexagon[] hexes = {
    Hex( 0, 0, palette3[0]),

    Hex( 0,-1),
    Hex( 0,-2),
    Hex(-1, 0),
    Hex(-2, 0, palette3[0]),
    Hex(-1, 1),
    Hex(-2, 2),
    Hex( 0, 1),
    Hex( 1, 0),
    Hex( 2, 0),

    Hex( 2,-2),
    Hex(-1,-1),
    Hex(-2, 1),
    Hex(-1, 2),
    Hex( 1, 1),
    Hex( 2,-1, palette3[0]),
    Hex( 1,-2),

    Hex(-3, 0),
    Hex(-2,-1),
    Hex(-1,-2),
    Hex( 0,-3),
    Hex( 1,-3),
    Hex( 2,-3),
    Hex( 3,-3),
    Hex( 3,-2),
    Hex( 3,-1),
    Hex( 3, 0),
    Hex( 2, 1),
    Hex( 1, 2),
    Hex( 0, 3),
    Hex(-1, 3),
    Hex(-2, 3),
    Hex(-3, 3),
    Hex(-3, 2),
    Hex(-3, 1),

    Hex( 0, 2, gray(0.1)),
    Hex( 1,-1, gray(0.1))
};

// Array of bombs
Bomb[] bombs = {
    Bomb.Bomb(Hex( 0, 0), graphic("fat_bomb.eps", "width=14mm"), 3),
    Bomb.Bomb(Hex(-2, 0), graphic("thin_bomb.eps", "width=8mm"), 1),
    Bomb.Bomb(Hex( 2,-1), graphic("thin_bomb.eps", "width=8mm"), 3),
};

bool should_display_coordinates(Hexagon hex)
{
    if (hex.fill_color == gray(0.1))
        return false;

    if (turn > 6)
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
    if (coordinates_equals(hex, coordinates_to_highlight))
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

    // Draw the bombs
    if (draw_bomb)
    {
        for (Bomb bomb : bombs)
        {
            bomb.draw(draw_delay=true);
        }
    }

    if (highlight_cells)
    {
        for (Hexagon hex : hexes)
        {
            if (should_highlight_coordinates(hex))
            {
                hex.border_color = linewidth(3);
                hex.draw(draw_coordinates=should_display_coordinates(hex));
                hex.border_color = black;
            }
        }
    }

    shipout(filename);
    restore();
}

int[] indexes_bomb0 = {0, 2, 3, 4, 6, 11, 12, 17, 18, 34};
int[] indexes_bomb1 = {1, 5, 7, 8, 9, 13, 14, 15, 16, 18};
int[] indexes_bomb2 = {10, 22, 24, 25, 27};

void doTurn()
{
    turn = turn + 1;

    if (turn == 1)
    {
        for (Bomb bomb : bombs)
        {
            bomb.delay = bomb.delay - 1;
        }

        coordinates_to_highlight = Hex(-2, 0);
    }
    else if (turn == 2)
    {
        // Explosion area of the bomb at (-2, 0)
        for (int index : indexes_bomb0)
        {
            hexes[index].fill_color = orange;
        }
    }
    else if (turn == 3)
    {
        coordinates_to_highlight = Hex( 0, 0);
    }
    else if (turn == 4)
    {
        // Explosion area of the bomb at ( 0, 0)
        for (int index : indexes_bomb1)
        {
            hexes[index].fill_color = orange;
        }
    }
    else if (turn == 5)
    {
        coordinates_to_highlight = Hex( 2,-1);
    }
    else if (turn == 6)
    {
        // Explosion area of the bomb at ( 2,-1)
        for (int index : indexes_bomb2)
        {
            hexes[index].fill_color = orange;
        }
    }
    else if (turn == 7)
    {
        draw_bomb = false;
        coordinates_to_highlight = Hex(42,42);

        for (int index : indexes_bomb0)
            hexes[index].fill_color = palette3[0];
        for (int index : indexes_bomb1)
            hexes[index].fill_color = palette3[0];
        for (int index : indexes_bomb2)
            hexes[index].fill_color = palette3[0];
    }

    /*
Hex( 0, 0, palette3[0]),        0

Hex( 0,-1),                     1
Hex( 0,-2),
Hex(-1, 0),
Hex(-2, 0, palette3[0]),
Hex(-1, 1),
Hex(-2, 2),
Hex( 0, 1),
Hex( 1, 0),
Hex( 2, 0),

Hex( 2,-2),                     10
Hex(-1,-1),
Hex(-2, 1),
Hex(-1, 2),
Hex( 1, 1),
Hex( 2,-1, palette3[0]),
Hex( 1,-2),

Hex(-3, 0),                     17
Hex(-2,-1),
Hex(-1,-2),
Hex( 0,-3),                     20
Hex( 1,-3),
Hex( 2,-3),
Hex( 3,-3),
Hex( 3,-2),
Hex( 3,-1),                     25
Hex( 3, 0),
Hex( 2, 1),
Hex( 1, 2),
Hex( 0, 3),
Hex(-1, 3),                     30
Hex(-2, 3),
Hex(-3, 3),
Hex(-3, 2),
Hex(-3, 1),

Hex( 0, 2, gray(0.1)),          35
Hex( 1,-1, gray(0.1))

    */
}

render("explosion_chain_reaction" + string(turn));

for (int i = 0; i < 7; ++i)
{
    doTurn();
    render("explosion_chain_reaction" + string(turn));
}
