from hexagon access *;

// Draw the axes
draw_axes();

real alpha = 0.97;
// Array of cells to plot
Hexagon[] hexes = {
    Hex(0, 0, white+opacity(alpha)),
    Hex(1, 0, white+opacity(alpha)),
    Hex(1,-1, white+opacity(alpha)),
    Hex(0,-1, white+opacity(alpha)),
    Hex(-1,0, white+opacity(alpha)),
    Hex(-1,1, white+opacity(alpha)),
    Hex(0, 1, white+opacity(alpha))
};

// Draw the hexagons
for (Hexagon hex : hexes)
{
    hex.draw(true);
}
