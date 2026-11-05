import subprocess
import time
import ctypes
from ctypes import wintypes
import sys

# Configure stdout for utf-8
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

kernel32 = ctypes.windll.kernel32
GENERIC_READ = 0x80000000
GENERIC_WRITE = 0x40000000
FILE_SHARE_READ = 1
FILE_SHARE_WRITE = 2
OPEN_EXISTING = 3

class COORD(ctypes.Structure):
    _fields_ = [("X", wintypes.SHORT), ("Y", wintypes.SHORT)]

class SMALL_RECT(ctypes.Structure):
    _fields_ = [("Left", wintypes.SHORT), ("Top", wintypes.SHORT),
                ("Right", wintypes.SHORT), ("Bottom", wintypes.SHORT)]

class CONSOLE_SCREEN_BUFFER_INFO(ctypes.Structure):
    _fields_ = [("dwSize", COORD),
                ("dwCursorPosition", COORD),
                ("wAttributes", wintypes.WORD),
                ("srWindow", SMALL_RECT),
                ("dwMaximumWindowSize", COORD)]

class KEY_EVENT_RECORD(ctypes.Structure):
    _fields_ = [("bKeyDown", wintypes.BOOL),
                ("wRepeatCount", wintypes.WORD),
                ("wVirtualKeyCode", wintypes.WORD),
                ("wVirtualScanCode", wintypes.WORD),
                ("UnicodeChar", wintypes.WCHAR),
                ("dwControlKeyState", wintypes.DWORD)]

class INPUT_RECORD_UNION(ctypes.Union):
    _fields_ = [("KeyEvent", KEY_EVENT_RECORD)]

class INPUT_RECORD(ctypes.Structure):
    _fields_ = [("EventType", wintypes.WORD),
                ("Event", INPUT_RECORD_UNION)]

def send_key(hIn, vk, scan, ch, ctrl_state=0):
    rec = INPUT_RECORD()
    rec.EventType = 1
    rec.Event.KeyEvent.bKeyDown = True
    rec.Event.KeyEvent.wRepeatCount = 1
    rec.Event.KeyEvent.wVirtualKeyCode = vk
    rec.Event.KeyEvent.wVirtualScanCode = scan
    rec.Event.KeyEvent.UnicodeChar = ch
    rec.Event.KeyEvent.dwControlKeyState = ctrl_state
    written = wintypes.DWORD()
    kernel32.WriteConsoleInputW(hIn, ctypes.byref(rec), 1, ctypes.byref(written))
    time.sleep(0.05)
    rec.Event.KeyEvent.bKeyDown = False
    kernel32.WriteConsoleInputW(hIn, ctypes.byref(rec), 1, ctypes.byref(written))
    time.sleep(0.1)

hConOut = kernel32.CreateFileA(b"CONOUT$", GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, None, OPEN_EXISTING, 0, 0)
hConIn = kernel32.CreateFileA(b"CONIN$", GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, None, OPEN_EXISTING, 0, 0)

csbi = CONSOLE_SCREEN_BUFFER_INFO()
kernel32.GetConsoleScreenBufferInfo(hConOut, ctypes.byref(csbi))
width = csbi.dwSize.X
top_row = csbi.srWindow.Top

print("[*] Launching build/dn.exe...")
proc = subprocess.Popen(['build/dn.exe'])
time.sleep(2.0)

buf = ctypes.create_string_buffer(width)
read = wintypes.DWORD()

def dump_screen(title):
    print(f"\n--- {title} ---")
    for y in range(top_row, top_row + 25):
        kernel32.ReadConsoleOutputCharacterA(hConOut, buf, width, COORD(0, y), ctypes.byref(read))
        line_str = buf.raw[:read.value].decode('cp866', errors='replace').rstrip()
        print(f"[{y-top_row:02d}]: {line_str}")

dump_screen("Initial Dual Panels")

# 1. Press Down Arrow 3 times
print("[*] Pressing Down Arrow 3 times...")
for _ in range(3):
    send_key(hConIn, 0x28, 0x50, '\0') # VK_DOWN
time.sleep(0.3)
dump_screen("After Down Arrow Navigation")

# 2. Press Tab to switch active panel
print("[*] Pressing Tab to switch active panel...")
send_key(hConIn, 0x09, 0x0F, '\t') # VK_TAB
time.sleep(0.3)
dump_screen("After Tab (Right Panel Active)")

# 3. Press F9 (Menu bar)
print("[*] Pressing F9 to open top menu...")
send_key(hConIn, 0x78, 0x43, '\0') # VK_F9
time.sleep(0.3)
dump_screen("After F9 (Top Menu Pulldown)")

# 4. Press Esc to dismiss menu
print("[*] Pressing Esc to close menu...")
send_key(hConIn, 0x1B, 0x01, '\x1b') # VK_ESCAPE
time.sleep(0.3)

# 5. Quit with Alt+X + Enter
print("[*] Pressing Alt+X and Enter to quit...")
send_key(hConIn, ord('X'), 0x2D, 'x', ctrl_state=0x0002)
time.sleep(0.5)
send_key(hConIn, 0x0D, 0x1C, '\r')

proc.wait(timeout=5)
print(f"\n[+] Full Interactive Session Completed Cleanly! Exit code: {proc.returncode}")
