from hexagon access *;

struct Player
{
    // Coordinates
    Hexagon hex;

    // Content (probably loaded by graphic)
    string image;

    static Player Player(Hexagon position, string image)
    {
        Player p = new Player;
        p.hex = position;
        p.image = image;
        return p;
    }

    void draw()
    {
        label(image, hex.cartesian_coordinates());
    }
};
