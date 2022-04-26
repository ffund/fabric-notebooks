SOURCES := $(wildcard *.md)
NBS := $(patsubst %.md,%.ipynb,$(SOURCES))
PDFS := $(patsubst %.md,%.pdf,$(SOURCES))

PANDOCFLAGS=--pdf-engine=xelatex\
         -V mainfont='Fira Sans' \
         -V geometry:margin=1in \
         --highlight-style pygments \
	 --listings --variable urlcolor=Maroon \
	 -H style/listings-setup.tex -H style/keystroke-setup.tex -H style/includes.tex

%.ipynb: %.md
	pandoc  --self-contained  $^ -o $@

%.pdf: %.md
	pandoc $^ $(PANDOCFLAGS) -o $@

all: $(NBS) $(PDFS)

notebooks: $(NBS)

pdfs: $(PDFS)


