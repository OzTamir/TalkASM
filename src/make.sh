nasm -f elf client.asm
gcc -o client client.o `pkg-config --cflags --libs gtk+-3.0` -lc 'util.c'
  
nasm -f elf server.asm 
gcc -o server server.o `pkg-config --cflags --libs gtk+-3.0` -lc 'util.c'