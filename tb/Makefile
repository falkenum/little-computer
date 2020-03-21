SOURCES := $(wildcard *_tb.v)
FILES := $(SOURCES:.v=.exe)
TB_SUFFIX := _tb

all: $(FILES)

%$(TB_SUFFIX).exe: %$(TB_SUFFIX).v
	iverilog -g2012 -o $@ -I ../h/ ../v/* $^

clean:
	rm *.exe
