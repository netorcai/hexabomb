from hexagon access *;

struct Bomb
{
    // Coordinates
    Hexagon hex;

    // Content (probably loaded by graphic)
    string image;

    // Number of turns before explosion
    int delay;

    static Bomb Bomb(Hexagon position, string image, int delay)
    {
        Bomb b = new Bomb;
        b.hex = position;
        b.image = image;
        b.delay = delay;
        return b;
    }

    void draw(bool draw_delay=false, pen text_font=white)
    {
        pair cell_center = hex.cartesian_coordinates();
        label(image, cell_center);

        if (draw_delay)
        {
            label(string(delay), cell_center, align=down, text_font);
        }
    }
};
