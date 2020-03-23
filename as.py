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

def get_machine_code(instr_str):
    instr_split = instr_str.split()
    op_str = instr_split[0]
    assert(op_str in op_to_code)
    opcode = op_to_code[op_str]
    instr = opcode << 12

    if op_str in {"halt", "nop"}:
        return instr 
        
    inst_i = 1
    first_arg = 0
    # if it is itype
    if instr_split[inst_i][0] != 'r':
        assert(int(instr_split[1]) < (1 << 6))
        first_arg = int(instr_split[1])
    else:
        # else it's a register
        first_arg = int(instr_split[inst_i][1:])
        assert(first_arg < 8)

    instr += first_arg << 6
    inst_i += 1

    # if it's a three arg instruction
    if op_str not in {"not"}:
        assert(instr_split[inst_i][0] == 'r')
        second_arg = int(instr_split[inst_i][1:]) 
        assert(second_arg < 8)
        instr += second_arg << 3
        inst_i += 1
    
    # else it's two arg (not)
    assert(instr_split[inst_i][0] == 'r')
    third_arg = int(instr_split[inst_i][1:]) 
    assert(third_arg < 8)
    instr += third_arg
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

    # if it's a comment
    if instr_str[0] == "#":
        continue

    try:
        instr = get_machine_code(instr_str)
    except Exception as e:
        subprocess.call(['rm', '-f', filename])
        raise e
    fout.write(f"{instr:04X}\n")

fout.close()
