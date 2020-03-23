TB_SOURCES := $(wildcard *_tb.sv)
SOURCES := ../sv/*.sv
INCLUDE_DIR := ../vh/
EXECUTABLES := $(TB_SOURCES:.sv=.exe)

all: $(EXECUTABLES)
%_tb.exe: %_tb.sv $(SOURCES)
	iverilog -g2012 -o $@ -I $(INCLUDE_DIR) $^

clean:
	rm -f *.exe
