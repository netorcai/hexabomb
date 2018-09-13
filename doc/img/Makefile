ASY= offsets.pdf
PDF= $(ASY:.asy=.pdf)
PNG= $(PDF:.pdf=.png)

all: ${PDF} ${PNG}

%.pdf: %.asy
	asy $<

%.png: %.pdf
	convert -density 150 $< -quality 100 -background white -alpha remove $@

mrproper:
	rm -f ${PDF} ${PNG}

update-view:
	@killall -SIGHUP llpp &> /dev/null || true # update pdf viewer
