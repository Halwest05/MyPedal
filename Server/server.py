import socket
import threading
import time
import sys

try:
    from pynput.keyboard import Key, Controller
except ImportError:
    print("❌ ERROR: Please install pynput module first.")
    sys.exit(1)

keyboard = Controller()

UDP_PORT = 8002
BROADCAST_PORT = 8003

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
            text = data.decode('utf-8', errors='ignore')
            
            if "d" in text:
                keyboard.press(Key.alt_gr)
                print(f"[{addr[0]}] ⬇️ Sustain pedal DOWN")
            elif "u" in text:
                keyboard.release(Key.alt_gr)
                print(f"[{addr[0]}] ⬆️ Sustain pedal UP")
                
        except Exception:
            # Silently ignore errors to keep the server running smoothly
            pass

if __name__ == "__main__":
    print("\n" + "="*50)
    print("      MYPEDAL SERVER - VIRTUAL SUSTAIN PEDAL")
    print(f"      Made by Halwest!")
    print("="*50)
    
    # Start the broadcaster
    t1 = threading.Thread(target=discovery_broadcaster, daemon=True)
    t1.start()
    
    try:
        cmd_server()
    except KeyboardInterrupt:
        print("\nShutting down server... Goodbye!")