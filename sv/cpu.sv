`include "defs.h"

module cpu(
    input CLK
);
	reg [`RegWidth-1:0] pc = 0;
	reg [`RegWidth-1:0] instr_mem [`InstrMemLen-1:0];
endmodule
