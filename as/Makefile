MEMSOURCES=$(wildcard *.as) ../as.py
MEMFILES=$(MEMSOURCES:.as=.mem)

all: $(MEMFILES)

%.mem: %.as
	python3 ../as.py $^
clean:
	rm -f *.mem