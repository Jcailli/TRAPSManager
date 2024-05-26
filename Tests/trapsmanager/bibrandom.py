import socket
import sys
import random
import time

# python3 trapscanoe.py 10.194.58.112 63594 [bib number max]

if (len(sys.argv)<3) :
    print("The script sends 25 penalties for a random bib :")
    print("[ip] [port] [bib number max]")
    sys.exit(0)

ip = sys.argv[1] 
port = sys.argv[2] 
bibnumbermax = sys.argv[3] 

while True:

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((ip, int(port)))
    bib = random.randint(1,int(bibnumbermax))
    message = '{"command":1,"bib":'+str(bib)+',"penaltyList":{"1":0, "2":2, "3":50, "4":0, "5":2, "6":50, "7":0, "8":2, "9":50, "10":0, "11":2, "12":50, "13":0, "14":2, "15":50, "16":0, "17":2, "18":50, "19":0, "20":2}}\x04'
    print(message)
    sock.send(message.encode())
    data = sock.recv(2000)
    print(data)
    time.sleep(1)
    sock.close()
