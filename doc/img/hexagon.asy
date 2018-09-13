settings.outformat = "pdf";
unitsize(1cm);

// This is the base polygon. The rotation makes it pointy hat.
path base_hexagon = rotate(30) * polygon(6);

// Compute base_length: the length of one hexagon side
pair a = point(base_hexagon, 0);
pair b = point(base_hexagon, 1);
real base_length = sqrt((a.x-b.x)^2 + (a.y-b.y)^2);

struct Hexagon
{
    // Axial coordinates
    int q;
    int r;

    // Misc attributes
    pen fill_color;
    pen border_color;

    pair cartesian_coordinates()
    {
        // from https://www.redblobgames.com/grids/hexagons/#hex-to-pixel
        real x = base_length * (sqrt(3.0) * q + sqrt(3.0) / 2.0 * r);
        real y = base_length * (                    -3.0  / 2.0 * r);
        return (x,y);
    }

    void draw(bool draw_coordinates = false)
    {
        // The polygon itself
        pair pos = cartesian_coordinates();
        fill(shift(pos) * base_hexagon, fill_color);
        draw(shift(pos) * base_hexagon, border_color);

        if (draw_coordinates)
        {
            string text = "(" + string(q) + "," + string(r) + ")";
            label(text, pos);
        }
    }
};

Hexagon Hex(int q, int r, pen fill_color=white, pen border_color=black)
{
    Hexagon hex = new Hexagon;
    hex.q = q;
    hex.r = r;
    hex.fill_color = fill_color;
    hex.border_color = border_color;
    return hex;
}

void draw_axes(real arrow_width=1.5, real arrow_length=3.5, real label_offset=0.3,
    pen x_color=black, pen y_color=black, pen z_color=black,
    bool draw_labels_plus=true,
    bool draw_labels_minus=true)
{
    real length = arrow_length * base_length;
    real label_length = (arrow_length + label_offset) * base_length;
    
    // Points fpr arrows
    pair xp = rotate(60*0) * shift(length) * (0,0);
    pair yp = rotate(60*1) * shift(length) * (0,0);
    pair zp = rotate(60*2) * shift(length) * (0,0);
    pair xn = rotate(60*3) * shift(length) * (0,0);
    pair yn = rotate(60*4) * shift(length) * (0,0);
    pair zn = rotate(60*5) * shift(length) * (0,0);

    // Arrows
    draw(xn..xp, x_color + arrow_width, Arrow(10));
    draw(yn..yp, y_color + arrow_width, Arrow(10));
    draw(zn..zp, z_color + arrow_width, Arrow(10));

    // Labels
    if (draw_labels_plus)
    {
        label("$x^{+}$", rotate(60*0) * shift(label_length) * (0,0), x_color);
        label("$y^{+}$", rotate(60*1) * shift(label_length) * (0,0), y_color);
        label("$z^{+}$", rotate(60*2) * shift(label_length) * (0,0), z_color);
    }

    if (draw_labels_minus)
    {
        label("$x^{-}$", rotate(60*3) * shift(label_length) * (0,0), x_color);
        label("$y^{-}$", rotate(60*4) * shift(label_length) * (0,0), y_color);
        label("$z^{-}$", rotate(60*5) * shift(label_length) * (0,0), z_color);
    }

}
