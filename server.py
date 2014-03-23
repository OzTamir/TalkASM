import socket

server = socket.socket()
server.bind(('127.0.0.1',1728))
server.listen(0)

# Listening loop
# Get incoming connection's socket & input
client, address = server.accept()
length = client.recv(1024)#.decode()
print length
client.close()

# Close the socket and terminate the connection
server.close()