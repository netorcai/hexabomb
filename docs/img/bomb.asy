from hexagon access *;

struct Bomb
{
    // Coordinates
    Hexagon hex;

    // Content (probably loaded by graphic)
    string image;

    // Number of turns before explosion
    int timer;

    static Bomb Bomb(Hexagon position, string image, int timer)
    {
        Bomb b = new Bomb;
        b.hex = position;
        b.image = image;
        b.timer = timer;
        return b;
    }

    void draw()
    {
        label(image, hex.cartesian_coordinates());
    }
};
