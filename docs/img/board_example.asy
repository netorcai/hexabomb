from hexagon access *;
from player access *;
from bomb access *;
from palette access palette3;

// Array of cells to plot
Hexagon[] hexes = {
    Hex(0 , 0),
    Hex(1 , 0, palette3[0]),
    Hex(1 ,-1, gray(0.1)),
    Hex(0 ,-1, gray(0.1)),
    Hex(-1, 0, palette3[1]),
    Hex( 0, 1, gray(0.1)),
    Hex(-1, 1, gray(0.1)),

    Hex(2 , 0, palette3[0]),
    Hex(2 ,-2),
    Hex(0 ,-2),
    Hex(-2, 0, palette3[1]),
    Hex( 0, 2),
    Hex(-2, 2),
    Hex(-1,-1, palette3[1]),
    Hex(-2, 1, palette3[1]),
    Hex(-1, 2),
    Hex( 1, 1, palette3[0]),
    Hex( 2,-1, palette3[0]), // bomb here
    Hex( 1,-2)
};

// Array of players
Player[] players = {
    Player.Player(0, "Blue", Hex( 1, 0), graphic("char.eps", "width=1.1cm")),
    Player.Player(1, "Green", Hex(-1, 0), graphic("char.eps", "width=1.1cm"))
};

// Array of bombs
Bomb[] bombs = {
    Bomb.Bomb(Hex(-2, 1), graphic("bomb.eps", "width=8mm"), 3)
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
