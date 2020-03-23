TB_SOURCES := $(wildcard *_tb.sv)
SOURCES := ../sv/*.sv
INCLUDE_DIR := ../vh/
EXECUTABLES := $(TB_SOURCES:.sv=.exe)
TB_SUFFIX := _tb

all: $(EXECUTABLES)

%$(TB_SUFFIX).exe: %$(TB_SUFFIX).sv $(SOURCES)
	iverilog -g2012 -o $@ -I $(INCLUDE_DIR) $^

clean:
	rm *.exe
