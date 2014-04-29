client: client.o    
	gcc -o client client.o `pkg-config --cflags --libs gtk+-3.0` -lc 'Server/util.c'

client.o: client.asm
	nasm -f elf client.asm 
