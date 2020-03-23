TB_SOURCES := $(wildcard *_tb.v)
SOURCES := ../sv/*.sv
INCLUDE_DIR := ../svh/
EXECUTABLES := $(TB_SOURCES:.v=.exe)
TB_SUFFIX := _tb

all: $(EXECUTABLES)

%$(TB_SUFFIX).exe: %$(TB_SUFFIX).v $(SOURCES)
	iverilog -g2012 -o $@ -I $(INCLUDE_DIR) $^

clean:
	rm *.exe
