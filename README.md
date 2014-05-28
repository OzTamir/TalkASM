TalkASM - Simple Chat written in x86 NASM
============

![TalkASM Preview](https://raw2.github.com/OzTamir/TalkASM/CLI/demo.png)

Main files
---
 - Server: Must be runned first. Runs the socket 'reciving' the connection.
 - Client: Connects to the server.

* The chat runs as default on port 43774, can be changed in "data.asm"
* Each program forks itself into two process - be sure to check out that both ended properly!


Other Files
---
 - sockets.asm: Contains the subroutines for the socket features (send, socketcall and such).
 - constant.asm: int 0x80 interrupts codes assigment to ease readabilty.
 - data.asm: Mostly strings to use during the run of the programs.
 - util.asm: Utilities subroutines to avoid duplicating code over the two versions (Input, Output, Exit and such).
 - compileServer.sh, compileClient.sh - Little bash scripts to compile and run on localhost
 
Compiling on Ubuntu 64bit
---
Those are the commands I've used to compile on my machine, this can be automated by using the bash scripts included in this repo.
If you have an urge to compile by hand, those are the commands (Replace 'client' with 'server' if needed):

```
nasm -o client.o -f elf32 -g client.asm 
ld -m elf_i386 client.o -o client
```
