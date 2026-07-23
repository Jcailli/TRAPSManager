from socket import *
import sys

#    input:
#
#    {
#       "command":0 (ask for list of bib)
#
#
#    }
#    {
#        "command":1, (set penalties)
#        "bib":123,
#        "penaltyList": {
#                "2": 0,
#                "5": 2,
#                "6": 50,
#        }
#
#    }
#    {
#        "command":2, (set start time)
#        "bib":123,
#        "time": 1456789
#
#    }
#    {
#        "command":3, (set finish time)
#        "bib":123,
#        "time": 1456789
#
#    }
#
#
#    output:
#    {
#        "bibList":[123,45,56,453],
#        "epoch":124567898
#    }
#    {
#        "response":0
#    }

def prompt():
    sys.stdout.write("> ");
    sys.stdout.flush()

def echo(message):
    sys.stdout.write(message);
    sys.stdout.flush()

broadcastSock = socket(AF_INET, SOCK_DGRAM)
broadcastSock.bind(('',5432))
echo("Wainting for TRAPSManager broadcast on port 5432...\n")

bm = broadcastSock.recvfrom(1024)
hello = bm[0].decode()
hellotab = hello.split(',')
ip = hellotab[1]
port = hellotab[2]

echo("TRAPSManager detected: "+ip+":"+port+"\n")    

#keep reading stdin
while True:

    prompt()
    commandline = input()

    if commandline == "quit":
        sys.exit(0)

    if commandline == "":
        echo("Commands:\n")
        echo("l                     : get list of bibs\n")
        echo("p [bib] [penalty list]: send penalties, ex: p 3 1:0,2:2,3:50\n") # gate 1, pen 0; gate 2, pen 2; gate 3, pen 50
        echo("s [bib] [Start time]  : send start time in ms since midnight\n")
        echo("f [bib] [Finish time] : send finish time in ms since midnight\n") 
        continue
                
    # split with spaces
    command = commandline.split(' ') 

    if (command[0]=="l"):
        message = '{"command":0}\x04'    
        echo(message+"\n")
        sock = socket(AF_INET, SOCK_STREAM)
        sock.connect((ip, int(port)))
        sock.send(message.encode())
        data = sock.recv(2000)
        echo(data.decode()+"\n")
        sock.close()
        continue

    if (command[0]=="p"):
        bib = command[1]
        penaltyList = command[2]
        penalties = penaltyList.split(',')
        message = '{"command":1,"bib":'+bib+',"penaltyList":{'
        index = 0
        for penpair in penalties:
            pentab = penpair.split(':')
            gate = pentab[0]
            pen = pentab[1]
            if (index>0): 
                message = message + ','
            message = message + '"'+gate+'":'+pen
            index = index+1
        
        message = message+'}}\x04'    
        echo(message+"\n")
        sock = socket(AF_INET, SOCK_STREAM)
        sock.connect((ip, int(port)))
        sock.send(message.encode())
        data = sock.recv(2000)
        echo(data.decode()+"\n")
        sock.close()
        continue

    if (command[0]=="p"):
        bib = command[1]
        starttime = command[2]
        message = '{"command":2,"bib":'+bib+',"time":'+starttime+'}\x04'    
        echo(message+"\n")
        sock = socket(AF_INET, SOCK_STREAM)
        sock.connect((ip, int(port)))
        sock.send(message.encode())
        data = sock.recv(2000)
        echo(data.decode()+"\n")
        sock.close()
        continue
    
    if (command[0]=="f"):
        bib = command[1]
        finishtime = command[2]
        message = '{"command":3,"bib":'+bib+',"time":'+finishtime+'}\x04'    
        echo(message+"\n")
        sock = socket(AF_INET, SOCK_STREAM)
        sock.connect((ip, int(port)))
        sock.send(message.encode())
        data = sock.recv(2000)
        echo(data.decode()+"\n")
        sock.close()
        continue
    
    echo("Unknown command: "+command)
