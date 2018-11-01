from hexagon access *;
from player access *;
from bomb access *;
from palette access palette3;

// Variables
int turn = 0;
bool draw_player1 = true;
bool draw_bomb = false;
bool highlight_exploded_cells = false;

// Array of cells to plot
Hexagon[] hexes = {
    // First 10 cells are the explosion range
    Hex(0 , 0, palette3[1]),
    Hex(0 ,-1),
    Hex(0 ,-2),
    Hex(-1, 0, palette3[1]),
    Hex(-2, 0),
    Hex(-1, 1),
    Hex(-2, 2),
    Hex( 0, 1),
    Hex(1 , 0, palette3[0]),
    Hex(2 , 0, palette3[0]),

    Hex(2 ,-2),
    Hex(-1,-1),
    Hex(-2, 1),
    Hex(-1, 2),
    Hex( 1, 1),
    Hex( 2,-1),
    Hex( 1,-2),

    Hex( 0, 2, gray(0.1)),
    Hex(1 ,-1, gray(0.1))
};

// Array of players
Player[] players = {
    Player.Player(0, "Blue",  Hex( 2, 0), graphic("char.eps", "width=1.1cm")),
    Player.Player(1, "Green", Hex( 0, 0), graphic("char.eps", "width=1.1cm"))
};

// Array of bombs
Bomb[] bombs = {
    Bomb.Bomb(Hex(0, 0), graphic("bomb.eps", "width=8mm"), 3)
};

void render(string filename)
{
    save();

    // Draw the hexagons
    for (Hexagon hex : hexes)
    {
        hex.draw(draw_coordinates=false);
    }

    if (highlight_exploded_cells)
    {
        for (int i = 0; i < 10; ++i)
        {
            hexes[i].fill_color = orange;
            hexes[i].draw(draw_coordinates=false);
            hexes[i].fill_color = palette3[1];
        }
    }

    // Draw the characters
    if (draw_player1)
        players[0].draw();
    players[1].draw();

    // Draw the bombs
    if (draw_bomb)
        bombs[0].draw(draw_delay=true);

    shipout(filename);
    restore();
}

void doTurn()
{
    turn = turn + 1;

    if (turn == 1)
    {
        draw_bomb = true;
    }
    else if (turn == 2)
    {
        players[1].hex = Hex(-1, 0);
        bombs[0].delay = 2;
    }
    else if (turn == 3)
    {
        players[1].hex = Hex(-1,-1);
        hexes[11].fill_color = palette3[1];
        bombs[0].delay = 1;
    }
}

// Turn 0. Initial situation.
render("explosion_turn" + string(turn));

// Turn 1. Player 1 plants a bomb and moves away from it.
doTurn();
render("explosion_turn" + string(turn));

// Turn 2. Player 1 moves out of the bomb explosion range.
doTurn();
render("explosion_turn" + string(turn));

// Turn 3. Nothing happens.
doTurn();
render("explosion_turn" + string(turn));

// Turn 4. Bomb explodes.
turn = turn + 1;
bombs[0].delay = 0;
highlight_exploded_cells = true;
render("explosion_turn" + string(turn) + "_before");

highlight_exploded_cells = false;
draw_player1 = false;
draw_bomb = false;
render("explosion_turn" + string(turn));
