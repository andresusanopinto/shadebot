shade:shade.c shade.pl
	plld -o shade shade.c shade.pl

clean:
	rm -f shade
	
doc.png:doc.dot
	dot doc.dot -Nstyle=filled -Nshape=record -Tpng -o doc.png
doc.svg:doc.dot
	dot doc.dot -Nstyle=filled -Nshape=record -Tsvg -o doc.svg
	