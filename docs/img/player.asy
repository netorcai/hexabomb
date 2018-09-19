from hexagon access *;

struct Player
{
    // Coordinates
    Hexagon hex;

    // Content (probably loaded by graphic)
    string image;

    // Display name
    string name;

    // Player ID
    int id;

    static Player Player(int id, string name, Hexagon position, string image)
    {
        Player p = new Player;
        p.id = id;
        p.name = name;
        p.hex = position;
        p.image = image;
        return p;
    }

    void draw()
    {
        label(image, hex.cartesian_coordinates());
    }
};
