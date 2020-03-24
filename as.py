import sys, subprocess
from pathlib import Path

op_to_code = {
    'addi': 0b0100,
    'add': 0b0000,
    'lsl': 0b0001,
    'and': 0b0010,
    'not': 0b0011,
    'halt': 0b1110,
    'nop': 0b1111
}
ktypes = {"halt", "nop"}
itypes = {"addi"}
rtypes = {"add", "lsl", "and"}
utypes = {"not"}

assert (ktypes | itypes | rtypes | utypes == op_to_code.keys())

def get_machine_code(instr_str):
    instr_split = instr_str.split()
    op_str = instr_split[0]
    assert(op_str in op_to_code)
    opcode = op_to_code[op_str]
    instr = opcode << 12

    if op_str in ktypes:
        return instr 
        
    inst_i = 1
    first_arg = 0
    # if it is itype
    if op_str in itypes:
        assert(instr_split[inst_i][0] != 'r')
        first_arg = int(instr_split[1])
        assert(first_arg < 32 and first_arg >= -32)
        first_arg = first_arg & 0x3f
    else:
        assert(op_str in rtypes | utypes)
        # else it's a register
        assert(instr_split[inst_i][0] == 'r')
        first_arg = int(instr_split[inst_i][1:])
        assert(first_arg < 8)

    instr |= first_arg << 6
    inst_i += 1

    # if it's a three arg instruction
    if op_str in rtypes | itypes:
        assert(instr_split[inst_i][0] == 'r')
        second_arg = int(instr_split[inst_i][1:]) 
        assert(second_arg < 8)
        instr += second_arg << 3
        inst_i += 1
    
    assert(instr_split[inst_i][0] == 'r')
    third_arg = int(instr_split[inst_i][1:]) 
    assert(third_arg < 8)
    instr |= third_arg
    return instr


if len(sys.argv) != 2:
    raise Exception("invalid call")

with open(sys.argv[1], 'r') as fin:
    read_data = fin.read()
instructions = read_data.split('\n')

filename = str(Path(sys.argv[1]).with_suffix('.mem'))
fout = open(filename, 'w')

for instr_str in instructions:
    instr_str = instr_str.strip()
    comment_start = instr_str.find('#')

    # if it's a comment
    if comment_start == 0:
        continue
    elif comment_start != -1:
        instr_str = instr_str[:comment_start]
    try:
        instr = get_machine_code(instr_str)
    except Exception as e:
        fout.close()
        subprocess.call(['rm', '-f', filename])
        raise e
    fout.write(f"{instr:04X}\n")

fout.close()
