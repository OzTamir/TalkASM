nasm -o client.o -f elf32 -g client.asm 
ld -m elf_i386 client.o -o client
./client
