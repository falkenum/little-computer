SOURCES=$(wildcard *.as) ../as.py
MEMFILES=$(SOURCES:.as=.mem)
ROMFILES=$(SOURCES:.as=.rom)

all: $(MEMFILES) $(ROMFILES)

%.rom: %.as
	python3 ../as.py $^
%.mem: %.as
	python3 ../as.py $^

clean:
	rm -f *.rom *.mem