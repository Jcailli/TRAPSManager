import socket
import sys

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

def print_args():
    sys.stdout.write("Arguments: [IP Address of CompetFFCK notification server] [port]\n")


# ##################################################################

if (len(sys.argv)<3) :
    print_args()
    sys.exit(1)

competIP = sys.argv[1] 
competPort = sys.argv[2] 

sys.stdout.write("Trying to connect to competFFCK at "+competIP+":"+competPort+"\n")
sys.stdout.flush()        

s.connect((competIP, int(competPort)))

sys.stdout.write("Connected to competFFCK at "+competIP+":"+competPort+"\n")
sys.stdout.flush()        

while True:
    data = s.recv(1000)
    print(data)
    if (len(data)==0):
        print("It looks like competFFCK has quit")
        sys.exit(0)
