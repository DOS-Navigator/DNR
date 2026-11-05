#!/usr/bin/env python3
import os

def dump_array(name, data):
    lines = []
    lines.append(f'const {name}_Size: LongInt = {len(data)};')
    lines.append(f'const {name}: array[0..{len(data)-1}] of Byte = (')
    chunks = [data[i:i+32] for i in range(0, len(data), 32)]
    for chunk_idx, chunk in enumerate(chunks):
        hex_bytes = ', '.join(f'${b:02X}' for b in chunk)
        if chunk_idx < len(chunks) - 1:
            lines.append(f'  {hex_bytes},')
        else:
            lines.append(f'  {hex_bytes}')
    lines.append(');')
    return '\n'.join(lines)

def main():
    build_dir = 'build'
    out_path = os.path.join('src', 'pascal', 'embedded_resources.inc')

    items = [
        ('DN.DLG', 'Embedded_DNDLG'),
        ('DN.LNG', 'Embedded_DNLNG'),
        ('DNRUS.DLG', 'Embedded_DNRUSDLG'),
        ('DNRUS.LNG', 'Embedded_DNRUSLNG'),
        ('DN.HLP', 'Embedded_DNHLP'),
        ('DNRUS.HLP', 'Embedded_DNRUSHLP'),
    ]

    lines = ['{ Automatically generated embedded default resources for standalone monolithic dn.exe }\n']

    for filename, varname in items:
        p = os.path.join(build_dir, filename)
        if not os.path.exists(p):
            print(f"Error: {p} not found.")
            return 1
        with open(p, 'rb') as f:
            data = f.read()
        print(f"Embedding {filename} ({len(data)} B) as {varname}...")
        lines.append(dump_array(varname, data))
        lines.append('\n')

    with open(out_path, 'w', encoding='latin-1') as f:
        f.write('\n'.join(lines))

    print(f"Successfully generated {out_path}")
    return 0

if __name__ == '__main__':
    exit(main())
