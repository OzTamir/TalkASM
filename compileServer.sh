nasm -o server.o -f elf32 -g server.asm 
ld -m elf_i386 server.o -o server
./server 22123
