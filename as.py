import sys
from pathlib import Path

op_to_code = {
    'addi': 0b0100,
    'add': 0b0000,
    'halt': 0b1110
}

with open(sys.argv[1], 'r') as file:
    read_data = file.read()
instructions = read_data.split('\n')


fout = open(Path(sys.argv[1]).with_suffix('.mem'), 'w')
for inst_str in instructions:
    inst_split = inst_str.split()
    assert(inst_split[0] in op_to_code)
    opcode = op_to_code[inst_split[0]]

    instr = opcode << 12
    if len(inst_split) > 1:
        
        first_arg = 0

        # if it is itype
        if inst_split[1][0] != 'r':
            assert(int(inst_split[1]) < (1 << 6))
            first_arg = int(inst_split[1])
        else:
            # else it's a register
            first_arg = int(inst_split[1][1:])
            assert(first_arg < 8)

        instr += first_arg << 6

        assert(inst_split[2][0] == 'r')
        second_arg = int(inst_split[2][1:]) 
        assert(second_arg < 8)
        instr += second_arg << 3

        assert(inst_split[3][0] == 'r')
        third_arg = int(inst_split[3][1:]) 
        assert(third_arg < 8)
        instr += third_arg
    
    fout.write(f"{instr:04X}\n")
    # print(f"{instr:04X}")

fout.close()
