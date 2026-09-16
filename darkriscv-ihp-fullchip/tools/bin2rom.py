#!/usr/bin/env python3
import argparse, pathlib
p=argparse.ArgumentParser(); p.add_argument('binary'); p.add_argument('-o','--output',default='rtl/boot_rom_case.vh'); a=p.parse_args()
d=pathlib.Path(a.binary).read_bytes(); d += bytes((-len(d)) % 4)
lines=[f"8'd{i}: boot_word = 32'h{int.from_bytes(d[i*4:i*4+4],'little'):08x};" for i in range(len(d)//4)]
pathlib.Path(a.output).write_text('\n'.join(lines)+'\n')
print(f"wrote {len(lines)} words to {a.output}")
