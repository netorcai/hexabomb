PDF=offsets.pdf score_turn0.pdf score_turn1.pdf score_turn2.pdf score_turn3.pdf board_example.pdf cell_types.pdf
SVG=$(PDF:.pdf=.svg)
PNG=$(PDF:.pdf=.png)
EPS=char_blue.eps char_green.eps char.eps thin_bomb.eps fat_bomb.eps

# Disable parallel build
.NOTPARALLEL:

all: ${EPS} ${PDF} ${PNG} ${SVG}

score_turn%.pdf: score.asy char_blue.eps char_green.eps
	asy $<

%.pdf: %.asy
	asy $<

%.svg: %.pdf
	inkscape -l $@ -f $<

%.png: %.pdf
	convert -density 150 $< -quality 100 $@

%.eps: %.svg
	inkscape -E $@ -f $<

mrproper:
	rm -f ${PDF} ${PNG} ${SVG} ${EPS}

update-view:
	@killall -SIGHUP llpp &> /dev/null || true # update pdf viewer
