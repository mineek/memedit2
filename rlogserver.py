import logging
import socket
import sys
import os

rlog_port = 1337

def udp_server(host="0.0.0.0", port=rlog_port):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind((host, port))

    while True:
        (data, addr) = s.recvfrom(128*1024)
        yield data

# clear log
os.remove("log.txt") if os.path.exists("log.txt") else None

for data in udp_server():
    print(data.decode('utf-8').strip())
    with open("log.txt", "a") as log_file:
        log_file.write(data.decode('utf-8'))
        log_file.write("\n")
