import os, sys, subprocess
from pathlib import Path

op_to_code = {
    'add': 0b0000,
    'lsl': 0b0001,
    'and': 0b0010,
    'not': 0b0011,
    'addi': 0b0100,
    'beq': 0b0101,
    'lw': 0b0110,
    'sw': 0b0111,
    'j': 0b1000,
    'halt': 0b1110,
    'nop': 0b1111
}
ktypes = {"halt", "nop"}
itypes = {"addi", "beq", "lw", "sw"}
rtypes = {"add", "lsl", "and"}
utypes = {"not"}
jtypes = {"j"}

def get_machine_code(instr_str, pc, labels):
    instr_split = instr_str.split()
    op_str = instr_split[0]
    assert(op_str in op_to_code)
    opcode = op_to_code[op_str]
    instr = opcode << 12

    if op_str in ktypes:
        return instr 
        
    inst_i = 1
    first_arg = 0

    if op_str in itypes:
        first_arg = instr_split[inst_i]

        # if it's not a number, it should be a label
        try:
            first_arg = int(first_arg)
        except ValueError:
            assert (first_arg in labels)
            subs_val = labels[first_arg]
            if op_str == "beq":
                first_arg = subs_val - (pc + 1)
            else:
                first_arg = subs_val

            first_arg = int(first_arg)

        # assert that it's 6 bits
        assert(first_arg >= -32 and first_arg < 32)
        first_arg &= 0x3f
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

def strip_comment(line):
    comment_start = line.find('#')
    # if it's a comment
    if comment_start != -1:
        return line[:comment_start]
    else:
        return line

def get_instructions(lines, labels):
    lines_i = 0
    instructions = []
    for line in lines:
        line = line.strip()
        line = strip_comment(line)

        if line == '':
            continue

        # if it's a label
        if line[-1] == ':':
            labels[line[:-1]] = lines_i
            continue

        instructions.append(line)
        lines_i += 1
    return instructions

def main():
    assert (ktypes | itypes | rtypes | utypes | jtypes == op_to_code.keys())

    if len(sys.argv) != 2:
        raise Exception("invalid call")

    with open(sys.argv[1], 'r') as fin:
        read_data = fin.read()

    lines = read_data.split('\n')

    filename = str(Path(sys.argv[1]).with_suffix('.mem'))
    fout = open(filename, 'w')

    labels = {}

    # convert instructions to machine code
    for pc, instr_str in enumerate(get_instructions(lines, labels)):
        try:
            instr = get_machine_code(instr_str, pc, labels)
        except Exception as e:
            fout.close()
            os.remove(filename)
            raise e
        fout.write(f"{instr:04X}\n")
    fout.close()

if __name__ == '__main__':
    main()