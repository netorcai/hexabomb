from hexagon access *;
from player access *;
from palette access palette3;

int[] cellCount = {1, 1};
int[] score = {1, 1};

pair turnOrigin = (2.75, 2);
pair cellCountOrigin = (2.75,0.75);
pair scoreOrigin = (2.75,-0.5);
pair playerOffset = (0, 0.5);

pen font = fontsize(10pt) + Helvetica(series="sb",shape="n");
int turn = 0;

// Array of cells to plot
Hexagon[] hexes = {
    Hex(0, 0),
    Hex(1, 0, palette3[0]),
    Hex(1,-1),
    Hex(0,-1),
    Hex(-1,0, palette3[1])
};

// Array of players
Player[] players = {
    Player.Player(0, "Blue", Hex( 1, 0), graphic("char.eps", "width=1.1cm")),
    Player.Player(1, "Green", Hex(-1, 0), graphic("char_asleep.eps", "width=1.2cm"))
};

// Invisible node to make sure all subfigs have the same size
draw(circle((4.7,0),0), invisible);

void render(string filename)
{
    save();

    // Draw a white background
    real xmin=-3;
    real ymin=-1;
    real xmax=5.5;
    real ymax=2.6;
    fill((xmin,ymin) -- (xmin,ymax) -- (xmax,ymax) -- (xmax,ymin) -- cycle, white);

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

    // Draw the turn
    label("turn " + string(turn), turnOrigin, right, font);

    int playerID = 0;
    while(playerID < 2)
    {
        pen textPen = font;

        // Draw the cell count
        string text = players[playerID].name + " \#cells: " + string(cellCount[playerID]);
        label(text, shift(playerOffset * playerID) * cellCountOrigin, right, textPen);

        // Draw the score
        text = players[playerID].name + " score: " + string(score[playerID]);
        label(text, shift(playerOffset * playerID) * scoreOrigin, right, textPen);

        playerID = playerID + 1;
    }


    shipout(filename);
    restore();
}

// Index of cells into which Blue moves
int[] blueMoves = {2, 0, 3};

void doTurn()
{
    // Blue moves
    players[0].hex = hexes[blueMoves[turn]];
    hexes[blueMoves[turn]].fill_color = palette3[0];

    turn = turn + 1;
    cellCount[0] = cellCount[0] + 1;

    score[0] = score[0] + cellCount[0];
    score[1] = score[1] + cellCount[1];
}



// First turn: initial values
render("score_turn" + string(turn));

// Second turn: player0 moves
doTurn();
render("score_turn" + string(turn));

// Third turn: player0 moves
doTurn();
render("score_turn" + string(turn));

// Fourth turn: player0 moves
doTurn();
render("score_turn" + string(turn));
