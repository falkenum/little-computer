import sys
import serial
import time

filename = sys.argv[1]
assert(filename)

ser = serial.Serial('/dev/ttyS8', 115200)
with open(filename, "rb") as f:
    byte = f.read(1)
    while byte:
        ser.write(byte)
        byte = f.read(1)
ser.close()
