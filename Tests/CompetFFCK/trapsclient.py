import socket
import sys

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

def prompt():
    sys.stdout.write("> ");
    sys.stdout.flush()

def print_args():
    sys.stdout.write("Arguments: [IP Address of CompetFFCK with TRAPS server] [port]\n")

def print_help():
    sys.stdout.write("Command list:\n\n")
    sys.stdout.write("quit              : Quit this terminal\n")
    sys.stdout.write("penalty 2 3 50    : Set penalty 50 at gate 3 for bib 2\n")
    sys.stdout.write("chrono 5 6230     : Set chrono to 6230 milliseconds for bib 5\n")
    sys.stdout.write("start 5 36000000  : Set start time to 10:00:00.000 for bib 5\n")
    sys.stdout.write("finish 5 36011450 : Set finish time to 10:00:11.450 for bib 5\n")
    sys.stdout.write("\n")
    sys.stdout.flush()


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
        message = 'penalty '+bib+' '+gate+' 1 '+penalty+'\r'    
        s.send(message.encode())
        continue

    #chrono
    if len(cmdItemList)==3 and cmdItemList[0]=="chrono":
        bib = cmdItemList[1]
        chrono = cmdItemList[2]
        message = 'chrono '+bib+' '+chrono+'\r'    
        s.send(message.encode())
        continue

    #start time
    if len(cmdItemList)==3 and cmdItemList[0]=="start":
        bib = cmdItemList[1]
        chrono = cmdItemList[2]
        message = 'start '+bib+' '+chrono+'\r'    
        s.send(message.encode())
        continue

    #finish time
    if len(cmdItemList)==3 and cmdItemList[0]=="finish":
        bib = cmdItemList[1]
        chrono = cmdItemList[2]
        message = 'finish '+bib+' '+chrono+'\r'    
        s.send(message.encode())
        continue

    #start
    if len(cmdItemList)==3 and cmdItemList[0]=="start":
        bib = cmdItemList[1]
        chrono = cmdItemList[2]
        message = 'start '+bib+' '+chrono+'\r'    
        s.send(message.encode())
        continue

    #finish
    if len(cmdItemList)==3 and cmdItemList[0]=="finish":
        bib = cmdItemList[1]
        chrono = cmdItemList[2]
        message = 'finish '+bib+' '+chrono+'\r'    
        s.send(message.encode())
        continue

    print_help()
    



    
