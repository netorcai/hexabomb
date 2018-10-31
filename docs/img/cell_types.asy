from hexagon access *;
from player access *;
from bomb access *;
from palette access palette3;

// Array of cells to plot
Hexagon[] hexes = {
    Hex( 0, 0),
    Hex(-1, 1, palette3[0]),
    Hex( 0, 1, palette3[1]),

    Hex(-2, 3, palette3[0]),
    Hex(-1, 3, palette3[1]),
    Hex(-2, 4, gray(0.1)),
    Hex(-2, 5, palette3[1])
};

// Array of players
Player[] players = {
    Player.Player(0, "Blue", Hex(-2, 3), graphic("char.eps", "width=1.1cm")),
    Player.Player(1, "Blue", Hex(-1, 3), graphic("char.eps", "width=1.1cm")),
};

// Array of bombs
Bomb[] bombs = {
    Bomb.Bomb(Hex(-2, 5), graphic("bomb.eps", "width=8mm"), 3),
};

// Draw the hexagons
for (Hexagon hex : hexes)
{
    hex.draw(false);
}

// Draw the characters
for (Player p : players)
{
    p.draw();
}

// Draw the bombs
for (Bomb b : bombs)
{
    b.draw();
}

// Labels
pen boldFont = fontsize(9) + font("OT1", "cmr", "b", "n");
pen font = fontsize(9) + font("OT1", "cmr", "m", "n");

label("Traversable cells", (-2,1.5), right, boldFont);
label("Empty (neutral color)", (2,0), right, font);
label("Empty (players' color)", (2,-1.5), right, font);

label("Non-traversable cells", (-2,-3), right, boldFont);
label("Characters", (2,-4.5), right, font);
label("Wall", (2,-6), right, font);
label("Bomb", (2,-7.5), right, font);
