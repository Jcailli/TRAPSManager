import socket
import sys
import random
import time

# python3 trapscanoe.py 10.194.58.112 63594 [bib number max]

if (len(sys.argv)<3) :
    print("The script sends chrono randomly:")
    print("[ip] [port] [bib number max]")
    sys.exit(0)

ip = sys.argv[1] 
port = sys.argv[2] 
bibnumbermax = sys.argv[3] 

while True:

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((ip, int(port)))
    bib = random.randint(1,int(bibnumbermax))
    chrono = random.randint(1,72000000)
    command = random.randint(2,3)
    message = '{"command":'+str(command)+',"bib":'+str(bib)+',"time":'+str(chrono)+'}\x04' 
    
    print(message)
    sock.send(message.encode())
    data = sock.recv(2000)
    print(data)
    time.sleep(0.5)
    sock.close()
