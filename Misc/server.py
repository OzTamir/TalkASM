import socket

def server():
	server = socket.socket()
	server.bind(('127.0.0.1',1728))
	server.listen(0)
	client, address = server.accept()
	asm = client.recv(1024)
	print asm
	client.close()
	server.close()

def client():
	client = socket.socket()
	client.connect(('127.0.0.1',43775))
	while True:
		client.send('EXIT\n')
	client.close()

if __name__ == '__main__':
	client()