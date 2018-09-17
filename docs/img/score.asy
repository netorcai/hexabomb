from hexagon access *;
from palette access palette3;

int[] cellCount = {1, 1};
int[] score = {1, 1};

pair turnOrigin = (2.75, 2);
pair cellCountOrigin = (2.75,0.75);
pair scoreOrigin = (2.75,-0.5);
pair playerOffset = (0, 0.5);

pen font_nobold=Helvetica(series="m",shape="n");
pen font=Helvetica(series="sb",shape="n");
int turn = 0;

// Array of cells to plot
Hexagon[] hexes = {
    Hex(0, 0),
    Hex(1, 0, palette3[0]),
    Hex(1,-1),
    Hex(0,-1),
    Hex(-1,0, palette3[1])
};

// Invisible node to make sure all subfigs have the same size
draw(circle((4.7,0),0), invisible);

void render(string filename)
{
    save();

    // Draw the hexagons
    for (Hexagon hex : hexes)
    {
        hex.draw(false);
    }

    // Draw the turn
    label("turn " + string(turn), turnOrigin, right, font_nobold);

    int playerID = 0;
    while(playerID < 2)
    {
        // Draw the cell count
        string text = "count: " + string(cellCount[playerID]);
        label(text, shift(playerOffset * playerID) * cellCountOrigin, right, font+palette3[playerID]);

        // Draw the score
        text = "score: " + string(score[playerID]);
        label(text, shift(playerOffset * playerID) * scoreOrigin, right, font+palette3[playerID]);

        playerID = playerID + 1;
    }


    shipout(filename);
    restore();
}

void doTurn()
{
    turn = turn + 1;
    cellCount[0] = cellCount[0] + 1;

    score[0] = score[0] + cellCount[0];
    score[1] = score[1] + cellCount[1];
}

// First turn: initial values
render("score_turn" + string(turn));

// Second turn: player0 moves
hexes[2].fill_color = palette3[0];
doTurn();
render("score_turn" + string(turn));

// Third turn: player0 moves
hexes[0].fill_color = palette3[0];
doTurn();
render("score_turn" + string(turn));

// Fourth turn: player0 moves
hexes[3].fill_color = palette3[0];
doTurn();
render("score_turn" + string(turn));
