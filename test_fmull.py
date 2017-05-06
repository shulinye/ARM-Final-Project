import struct

def fmull_test(x,y):
    x = struct.unpack('>f', bytes.fromhex(x))
    y = struct.unpack('>f', bytes.fromhex(y))
    return struct.pack('>f', x[0]*y[0])


