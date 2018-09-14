ASY= offsets.pdf score_turn0.pdf score_turn1.pdf score_turn2.pdf score_turn3.pdf
PDF= $(ASY:.asy=.pdf)
SVG= $(PDF:.pdf=.svg)
PNG= $(PDF:.pdf=.png)

# Disable parallel build
.NOTPARALLEL:

all: ${PDF} ${PNG} ${SVG}

score_turn%.pdf: score.asy
	asy $<

%.pdf: %.asy
	asy $<

%.svg: %.pdf
	inkscape -l $@ -f $<

%.png: %.pdf
	convert -density 150 $< -quality 100 -background white -alpha remove $@

mrproper:
	rm -f ${PDF} ${PNG}

update-view:
	@killall -SIGHUP llpp &> /dev/null || true # update pdf viewer
