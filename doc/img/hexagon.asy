settings.outformat = "pdf";
unitsize(1cm);

real point_size = 0.03;

// Polygons
string[] coord={"(+1,0)", "(+1,-1)", "(0,-1)", "(-1,0)", "(-1,+1)", "(0,+1)"};
path p0 = rotate(30) * polygon(6);

pair a = point(p0, 0);
pair b = point(p0, 1);
pair mab = (a+b)/2;

real l = length(mab - (0,0));
real arrow_width = 1.5;
real arrow_dist = 4;

// Drawing axes
pair xp = rotate(60*0) * shift(arrow_dist*l) * (0,0);
pair yp = rotate(60*1) * shift(arrow_dist*l) * (0,0);
pair zp = rotate(60*2) * shift(arrow_dist*l) * (0,0);
pair xn = rotate(60*3) * shift(arrow_dist*l) * (0,0);
pair yn = rotate(60*4) * shift(arrow_dist*l) * (0,0);
pair zn = rotate(60*5) * shift(arrow_dist*l) * (0,0);

// Colors (iwanthue)
pen color1 = rgb("000000");
pen color2 = rgb("000000");
pen color3 = rgb("000000");

draw(xn..xp, color1 + arrow_width, Arrow(10));
draw(yn..yp, color2 + arrow_width, Arrow(10));
draw(zn..zp, color3 + arrow_width, Arrow(10));

label("$x^{+}$", rotate(60*0) * shift((arrow_dist+0.4)*l) * (0,0), color1);
label("$y^{+}$", rotate(60*1) * shift((arrow_dist+0.4)*l) * (0,0), color2);
label("$z^{+}$", rotate(60*2) * shift((arrow_dist+0.4)*l) * (0,0), color3);
label("$x^{-}$", rotate(60*3) * shift((arrow_dist+0.4)*l) * (0,0), color1);
label("$y^{-}$", rotate(60*4) * shift((arrow_dist+0.4)*l) * (0,0), color2);
label("$z^{-}$", rotate(60*5) * shift((arrow_dist+0.4)*l) * (0,0), color3);

// Drawing polygons
real polygon_alpha = 0.97;
fill(p0, white + opacity(polygon_alpha));
label("(0,0)", (0,0));

for (int i = 0; i < 6; ++i)
{
    path p = rotate(60*i) * shift(2*l) * p0;
    fill(p, white + opacity(polygon_alpha));
    draw(p);

    pair c = rotate(60*i) * shift(2*l) * (0,0);
    label(coord[i], c);
}
