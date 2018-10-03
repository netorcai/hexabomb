PDF=offsets.pdf score_turn0.pdf score_turn1.pdf score_turn2.pdf score_turn3.pdf board_example.pdf cell_types.pdf
SVG=$(PDF:.pdf=.svg)
PNG=$(PDF:.pdf=.png)
EPS=char_blue.eps char_green.eps char.eps thin_bomb.eps fat_bomb.eps
GIF=explosion_thin.gif explosion_fat.gif

# Disable parallel build
.NOTPARALLEL:

all: ${EPS} ${PDF} ${PNG} ${SVG} ${GIF}

score_turn%.pdf: score.asy char_blue.eps char_green.eps
	asy $<

explosion_thin_turn%.pdf: explosion_thin.asy char.eps thin_bomb.eps
	asy $<

explosion_thin.gif: explosion_thin_turn0.png explosion_thin_turn1.png explosion_thin_turn2.png explosion_thin_turn3.png  explosion_thin_turn4_before.png explosion_thin_turn4.png
	convert -delay 100 -loop 0 $^ $@

explosion_fat_turn%.pdf: explosion_fat.asy char.eps fat_bomb.eps
	asy $<

explosion_fat.gif: explosion_fat_turn0.png explosion_fat_turn1.png explosion_fat_turn2.png explosion_fat_turn3.png  explosion_fat_turn4_before.png explosion_fat_turn4.png
	convert -delay 100 -loop 0 $^ $@

%.pdf: %.asy
	asy $<

%.svg: %.pdf
	inkscape -l $@ -f $<

%.png: %.pdf
	convert -density 150 $< -quality 100 $@

%.eps: %.svg
	inkscape -E $@ -f $<

mrproper:
	rm -f ${PDF} ${PNG} ${SVG} ${EPS} ${GIF}

update-view:
	@killall -SIGHUP llpp &> /dev/null || true # update pdf viewer
