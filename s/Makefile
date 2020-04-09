SOURCES=$(wildcard *.s) ../as.py
MEMFILES=$(SOURCES:.s=.mem)
ROMFILES=$(SOURCES:.s=.rom)

all: $(MEMFILES) $(ROMFILES)

%.rom: %.s
	python3 ../as.py $^
%.mem: %.s
	python3 ../as.py $^

clean:
	rm -f *.rom *.mem