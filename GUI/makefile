gui: gui.o    
	gcc -o gui gui.o `pkg-config --cflags --libs gtk+-3.0` -lc 'util.c'

gui.o: gui.asm
	nasm -f elf gui.asm 
