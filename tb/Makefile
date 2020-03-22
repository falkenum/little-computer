TB_SOURCES := $(wildcard *_tb.v) $(wildcard ../sv/*.sv)
SOURCES := $(wildcard ../sv/*.sv)
EXECUTABLES := $(TB_SOURCES:.v=.exe)
TB_SUFFIX := _tb

all: $(EXECUTABLES)

%$(TB_SUFFIX).exe: %$(TB_SUFFIX).v $(SOURCES)
	iverilog -g2012 -o $@ -I ../h/ $^

clean:
	rm *.exe
