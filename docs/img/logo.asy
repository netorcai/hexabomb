from hexagon access *;
from bomb access *;

Hexagon h = Hex(0,0);
h.border_color = linewidth(2);
Bomb b = Bomb.Bomb(h, graphic("bomb.eps", "width=8mm"), 3);

h.draw(draw_coordinates=false);
b.draw();

shipout("logo");
