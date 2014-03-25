nasm -o reShell.o -f elf32 -g remoteShell.asm 
ld -m elf_i386 reShell.o -o reShell
./reShell
