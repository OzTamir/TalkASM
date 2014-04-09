TalkASM - Simple Chat written in x86 NASM
============

![TalkASM Preview](https://raw2.github.com/OzTamir/TalkASM/master/demo.png)

Two main files:
---
 - Server: Must be runned first. Runs the socket 'reciving' the connection.
 - Client: Connects to the server.

* The chat runs as default on port 43774, can be changed in "data.asm"
* Each program forks itself into two process - be sure to check out that both ended properly!
 You can run 'killall server' or 'killall client' depending on which version you're runing.

Other Files:
---
 - sockets.asm: Contains the subroutines for the socket features (send, socketcall and such).
 - constant.asm: int 0x80 interrupts codes assigment to ease readabilty.
 - data.asm: Mostly strings to use during the run of the programs.
 - util.asm: Utilities subroutines to avoid duplicating code over the two versions (Input, Output, Exit and such).
