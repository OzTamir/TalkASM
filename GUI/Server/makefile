serverGUI: serverGUI.o    
	gcc -o serverGUI serverGUI.o `pkg-config --cflags --libs gtk+-3.0` -lc 'util.c'

serverGUI.o: serverGUI.asm
	nasm -f elf serverGUI.asm 
