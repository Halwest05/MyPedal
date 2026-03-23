import socket
import threading
import time
import sys
import ctypes

UDP_PORT = 8002
BROADCAST_PORT = 8003

# =====================================================================
# --- DIRECTINPUT FORGE: LOW-LEVEL WINDOWS C-TYPES ---
# This forces the OS to recognize a raw hardware scancode.
# =====================================================================
SendInput = ctypes.windll.user32.SendInput

PUL = ctypes.POINTER(ctypes.c_ulong)
class KeyBdInput(ctypes.Structure):
    _fields_ = [("wVk", ctypes.c_ushort),
                ("wScan", ctypes.c_ushort),
                ("dwFlags", ctypes.c_ulong),
                ("time", ctypes.c_ulong),
                ("dwExtraInfo", PUL)]

class HardwareInput(ctypes.Structure):
    _fields_ = [("uMsg", ctypes.c_ulong),
                ("wParamL", ctypes.c_short),
                ("wParamH", ctypes.c_ushort)]

class MouseInput(ctypes.Structure):
    _fields_ = [("dx", ctypes.c_long),
                ("dy", ctypes.c_long),
                ("mouseData", ctypes.c_ulong),
                ("dwFlags", ctypes.c_ulong),
                ("time", ctypes.c_ulong),
                ("dwExtraInfo", PUL)]

class Input_I(ctypes.Union):
    _fields_ = [("ki", KeyBdInput),
                ("mi", MouseInput),
                ("hi", HardwareInput)]

class Input(ctypes.Structure):
    _fields_ = [("type", ctypes.c_ulong),
                ("ii", Input_I)]

# Windows Flags
KEYEVENTF_EXTENDEDKEY = 0x0001
KEYEVENTF_KEYUP       = 0x0002
KEYEVENTF_SCANCODE    = 0x0008

# The hardware scancode for Alt is 0x38.
DIK_ALT = 0x38

def press_right_alt():
    extra = ctypes.c_ulong(0)
    ii_ = Input_I()
    # Scancode Flag (0x0008) + Extended Flag (0x0001) tells Windows it's Right Alt, not Left Alt
    ii_.ki = KeyBdInput(0, DIK_ALT, KEYEVENTF_SCANCODE | KEYEVENTF_EXTENDEDKEY, 0, ctypes.pointer(extra))
    x = Input(ctypes.c_ulong(1), ii_)
    SendInput(1, ctypes.pointer(x), ctypes.sizeof(x))

def release_right_alt():
    extra = ctypes.c_ulong(0)
    ii_ = Input_I()
    # Scancode (0x0008) + Extended (0x0001) + KeyUp (0x0002)
    ii_.ki = KeyBdInput(0, DIK_ALT, KEYEVENTF_SCANCODE | KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, 0, ctypes.pointer(extra))
    x = Input(ctypes.c_ulong(1), ii_)
    SendInput(1, ctypes.pointer(x), ctypes.sizeof(x))
# =====================================================================


def get_broadcast_addresses():
    bcast = ["<broadcast>", "255.255.255.255"]
    try:
        host = socket.gethostname()
        ips = socket.gethostbyname_ex(host)[2]
        for ip in ips:
            parts = ip.split('.')
            parts[-1] = '255'
            bcast.append('.'.join(parts))
    except Exception:
        pass
    return set(bcast)

def discovery_broadcaster():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    print(f"📡 Broadcasting presence on port {BROADCAST_PORT}...")
    
    while True:
        targets = get_broadcast_addresses()
        msg = b"PEDAL_SERVER_HERE"
        for t in targets:
            try:
                sock.sendto(msg, (t, BROADCAST_PORT))
            except Exception:
                pass
        time.sleep(1)

def cmd_server():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(("0.0.0.0", UDP_PORT))
    
    print(f"🎹 Pedal server listening for commands on UDP {UDP_PORT}...\n")
    
    while True:
        try:
            data, addr = sock.recvfrom(256)
            text = data.decode('utf-8', errors='ignore').lower()
            
            # Using our custom DirectInput C-functions
            if "d" in text:
                press_right_alt()
                print(f"[{addr[0]}] ⬇️ Sustain pedal DOWN (Raw Hardware R-Alt)")
            elif "u" in text:
                release_right_alt()
                print(f"[{addr[0]}] ⬆️ Sustain pedal UP (Raw Hardware R-Alt)")
                
        except Exception:
            pass

def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

if __name__ == "__main__":
    if not is_admin():
        print("🔄 Requesting administrative privileges...")
        ctypes.windll.shell32.ShellExecuteW(
            None, "runas", sys.executable, ' '.join([f'"{arg}"' for arg in sys.argv]), None, 1
        )
        sys.exit()

    print("\n" + "="*50)
    print("      MYPEDAL SERVER - VIRTUAL SUSTAIN PEDAL")
    print(f"      Made by Halwest! (DirectInput Mode ⚡)")
    print("="*50)
    
    t1 = threading.Thread(target=discovery_broadcaster, daemon=True)
    t1.start()
    
    try:
        cmd_server()
    except KeyboardInterrupt:
        # Safety catch to ensure the key isn't stuck down if you exit
        release_right_alt()
        print("\nShutting down server... Goodbye!")