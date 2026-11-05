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

    pairs = [
        ('DN.DLG', 'DN.LNG', 'Embedded_DNDLG', 'Embedded_DNLNG'),
        ('DNRUS.DLG', 'DNRUS.LNG', 'Embedded_DNRUSDLG', 'Embedded_DNRUSLNG'),
    ]

    lines = ['{ Automatically generated embedded default resources for standalone monolithic dn.exe }\n']

    for dlg_name, lng_name, dlg_var, lng_var in pairs:
        dlg_path = os.path.join(build_dir, dlg_name)
        lng_path = os.path.join(build_dir, lng_name)
        if not os.path.exists(dlg_path) or not os.path.exists(lng_path):
            print(f"Error: {dlg_path} or {lng_path} not found.")
            return 1
        with open(dlg_path, 'rb') as f:
            dlg = f.read()
        with open(lng_path, 'rb') as f:
            lng = f.read()
        print(f"Embedding {dlg_name} ({len(dlg)} B) and {lng_name} ({len(lng)} B)...")
        lines.append(dump_array(dlg_var, dlg))
        lines.append('\n')
        lines.append(dump_array(lng_var, lng))
        lines.append('\n')

    with open(out_path, 'w', encoding='latin-1') as f:
        f.write('\n'.join(lines))

    print(f"Successfully generated {out_path}")
    return 0

if __name__ == '__main__':
    exit(main())
