import socket
import sys
import random
import time

# python3 trapscanoe.py 10.194.58.112 63594 [bib number max]

if (len(sys.argv)<3) :
    print("The script sends penalties randomly:")
    print("[ip] [port] [bib number max]")
    sys.exit(0)

ip = sys.argv[1] 
port = sys.argv[2] 
bibnumbermax = sys.argv[3] 

while True:

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((ip, int(port)))
    bib = random.randint(1,int(bibnumbermax))
    gate = random.randint(1,25)
    penalty = random.randint(0,2)
    if penalty==1:
        penalty = 50
    message = '{"command":1,"bib":'+str(bib)+',"penaltyList":{"'+str(gate)+'":'+str(penalty)+'}}\x04'
    print(message)
    sock.send(message.encode())
    data = sock.recv(2000)
    print(data)
    time.sleep(0.5)
    sock.close()
