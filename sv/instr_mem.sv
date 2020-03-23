`include "defs.svh"

module instr_mem(
    input [`RegWidth-1:0] addr,
    output [`InstrWidth-1:0] instr
);
    reg [`InstrWidth-1:0] mem [(1 << `RegWidth)-1:0];
    assign instr = mem[addr];

    initial begin
        $readmemh(`INSTR_MEM, mem, 0, 3);
    end
endmodule
