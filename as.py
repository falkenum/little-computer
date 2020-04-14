import os, sys, subprocess, re, codecs
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
    'jl': 0b1001,
    'rts': 0b1010,
    'push': 0b1011,
    'pop': 0b1100,
    'blt': 0b1101,
    'halt': 0b1110,
    'nop': 0b1111
}
ktypes = {"halt", "nop", "rts"}
itypes = {"addi", "beq", "blt", "lw", "sw"}
rtypes = {"add", "lsl", "and"}
utypes = {"not"}
stypes = {"push", "pop"}
jtypes = {"j", "jl"}

def get_reg_num(reg_str):
    if reg_str == 'lr':
        reg_str = 'r7'
    assert(reg_str[0] == 'r')
    num = int(reg_str[1:])
    assert(num < 8)
    return num

def get_machine_code(instr_str, pc, labels):
    instr_split = instr_str.split()
    op_str = instr_split[0]

    if instr_split[0] == ".word":
        word_val = 0
        if instr_split[1] in labels:
            word_val = labels[instr_split[1]]
        else:
            word_val = int(instr_split[1], base=16)

        return word_val

    assert(op_str in op_to_code)
    opcode = op_to_code[op_str]
    instr = opcode << 12

    if op_str in ktypes:
        return instr 
        
    inst_i = 1
    first_arg = 0
    first_arg_shamt = 6

    if op_str in itypes:
        first_arg = instr_split[inst_i]

        # if it's not a number, it should be a label
        try:
            first_arg = int(first_arg)
        except ValueError:
            assert (first_arg in labels)
            subs_val = labels[first_arg]
            if op_str == "beq" or op_str == "blt":
                first_arg = subs_val - (pc + 1)
            else:
                first_arg = subs_val

            first_arg = int(first_arg)

        # assert that it's 6 bits
        assert(first_arg >= -32 and first_arg < 32)
        first_arg &= 0x3f
    elif op_str in jtypes:
        try:
            first_arg = instr_split[inst_i]
            first_arg = int(first_arg)
        except ValueError:
            assert (first_arg in labels)
            first_arg = int(labels[first_arg])
        assert(first_arg >= 0 and first_arg < 1 << 12)
        first_arg_shamt = 0
    elif op_str in rtypes | utypes:
        # else it's a register
        first_arg = get_reg_num(instr_split[inst_i])


    instr |= first_arg << first_arg_shamt
    if op_str not in stypes:
        inst_i += 1

    # if it's a three arg instruction
    if op_str in rtypes | itypes:
        second_arg = get_reg_num(instr_split[inst_i])
        instr += second_arg << 3
        inst_i += 1
    
    if op_str in rtypes | itypes | utypes:
        third_arg = get_reg_num(instr_split[inst_i])
        assert(third_arg < 8)
        instr |= third_arg
    elif op_str in stypes:
        third_arg = get_reg_num(instr_split[inst_i])
        instr |= third_arg
    return instr

def strip_comment(line):
    comment_start = line.find(';')
    # if it's a comment
    if comment_start != -1:
        return line[:comment_start]
    else:
        return line

def get_instructions(lines, labels):
    pc = 0
    instructions = []
    # indexed by pc
    pc_to_src_line = {} 

    for linenum, line in enumerate(lines):
        line = line.strip()
        line = strip_comment(line)

        if line == '':
            continue

        # if it's a label
        if line[-1] == ':':
            label = line[:-1]
            assert(label not in labels)
            array_label_match = re.match(r'(.+)@.+', label)
            if array_label_match:
                array_base_label = array_label_match.group(1)
                assert(array_base_label in labels)
                base_addr = labels[array_base_label]
                labels[label] = pc - base_addr
            else:
                labels[label] = pc
            continue

        # if it's a string directive, convert it to a bunch of word directives

        if line.split()[0] == ".string":
            literal = re.search(r'\.string "(.+)"', line).group(1)
            assert(literal)
            literal = codecs.decode(literal, 'unicode-escape')
            ba = bytearray(literal, 'ascii')
            for b in ba:
                instructions.append(f".word {b:04x}")
            
            instructions.append(".word 0000")
            pc += len(literal) + 1
            continue

        pc_to_src_line[pc] = linenum + 1
        instructions.append(line)
        pc += 1
    return pc_to_src_line, instructions

def main():
    assert (ktypes | itypes | rtypes | utypes | stypes | jtypes == op_to_code.keys())

    if len(sys.argv) != 2:
        raise Exception("invalid call")

    with open(sys.argv[1], 'r') as fin:
        read_data = fin.read()

    lines = read_data.split('\n')

    filename_rom = str(Path(sys.argv[1]).with_suffix('.rom'))
    fout_rom = open(filename_rom, 'wb')
    filename_mem = str(Path(sys.argv[1]).with_suffix('.mem'))
    fout_mem = open(filename_mem, 'w')

    labels = {}
    pc_to_src_line, instructions = get_instructions(lines, labels)

    # convert instructions to machine code
    for pc, instr_str in enumerate(instructions):
        try:
            instr = get_machine_code(instr_str, pc, labels)
        except Exception as e:
            fout_rom.close()
            fout_mem.close()
            os.remove(filename_rom)
            os.remove(filename_mem)
            print(f"ERROR at source line {pc_to_src_line[pc]:}")
            raise e
        fout_rom.write(instr.to_bytes(length=2, byteorder='little'))
        fout_mem.write(f"{instr:04X}\n")
    fout_rom.close()
    fout_mem.close()

if __name__ == '__main__':
    main()