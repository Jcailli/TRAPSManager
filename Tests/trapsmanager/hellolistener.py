from socket import *
from datetime import datetime

s = socket(AF_INET, SOCK_DGRAM)
s.bind(('',5432))
print("Wainting for TRAPSManager broadcast on port 5432...")
while (True):
    m = s.recvfrom(1024)
    hello = m[0].decode()
    print(datetime.now().time())
    print(hello)
    
