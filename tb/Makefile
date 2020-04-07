TB_SOURCES := $(wildcard *_tb.sv)
SOURCES := ../sv/*.sv
INCLUDE_DIR := ../vh/
EXECUTABLES := $(TB_SOURCES:.sv=.exe)
WARNING_FLAGS := -Wanachronisms -Wimplicit -Wimplicit-dimensions -Wportbind -Wselect-range -Wsensitivity-entire-array

all: $(EXECUTABLES)
%_tb.exe: %_tb.sv $(SOURCES)
	iverilog -g2012 $(WARNING_FLAGS) -o $@ -I $(INCLUDE_DIR) $^

clean:
	rm -f *.exe
