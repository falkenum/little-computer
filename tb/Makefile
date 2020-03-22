SOURCES := $(wildcard *_tb.v)
EXECUTABLES := $(SOURCES:.v=.exe)
TB_SUFFIX := _tb

all: $(EXECUTABLES)

%$(TB_SUFFIX).exe: %$(TB_SUFFIX).v
	iverilog -g2012 -o $@ -I ../h/ ../sv/*.sv $^

clean:
	rm *.exe
