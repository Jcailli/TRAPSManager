import socket
import sys
from threading import Thread

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

def prompt():
    sys.stdout.write("> ");
    sys.stdout.flush()

def print_args():
    sys.stdout.write("Arguments: [IP Address of CompetFFCK notification server] [port]\n")

def print_help():
    sys.stdout.write("Command list:\n\n")
    sys.stdout.write("quit           : Quit this terminal\n")
    sys.stdout.write("penalty 2 3 50 : Bib 2, gate 3, set penalty 50\n")
    sys.stdout.write("chrono 4 112230 : Bib 4, set chrono as 112230 milliseconds\n")
    sys.stdout.write("\n")
    sys.stdout.flush()

def receiver():
    try:
        while True:
            data = s.recv(1000)
            print("competFFCK says:", data)
            prompt()
    except Exception:
        pass


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

Thread(target=receiver).start()
    
#keep reading stdin
while True:

    prompt()
    commandline = input()

    if commandline == "quit":
        s.close()
        sys.exit(0)
            
    # split with spaces
    cmdItemList = commandline.split(' ') 

    #penalties
    if len(cmdItemList)==4 and cmdItemList[0]=="penalty":
        penalty = cmdItemList[3]
        gate = cmdItemList[2]
        bib = cmdItemList[1]
        sys.stdout.write("Setting penalty "+penalty+" at gate "+gate+" for bib "+bib+"\n")
        sys.stdout.flush()    
        message = 'bib\x02'+bib+'\x01gate\x02'+gate+'\x01embarcation\x021\x01penalty\x02'+penalty+'\x01owner\x02traps\x01key\x02<penalty_add>\x01\x06'    
        s.send(message.encode())
        continue   

    #chronos
    if len(cmdItemList)==3 and cmdItemList[0]=="chrono":
        chrono = cmdItemList[2]
        bib = cmdItemList[1]
        sys.stdout.write("Setting chrono "+chrono+" for bib "+bib+"\n")
        sys.stdout.flush()    
        message = 'passage\x02-1\x01bib\x02'+bib+'\x01time\x02'+chrono+'\x01key\x02<bib_time>\x01\x06'
        s.send(message.encode())
        continue
   

       #chrono
    if len(cmdItemList)==4 and cmdItemList[0]=="chrono":
        chrono = cmdItemList[1]
        bib = cmdItemList[3]
        sys.stdout.write("Setting chrono "+chrono+" for bib "+bib+"\n")
        sys.stdout.flush()    
        message = 'time\x02'+chrono+'\x01passage\x02-1\x01bib\x02'+bib+'\x01owner\x02traps\x01key\x02<toto_add>\x01\x06'    
        s.send(message.encode())
        continue

    print_help()
    



    