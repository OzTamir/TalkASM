;using sockets on linux with the 0x80 inturrprets.
;
;assemble
;  nasm -o socket.o -f elf32 -g socket.asm
;link
;  ld -o socket socket.o
;
; My Version:
;		nasm -o socket.o -f elf32 -g client.asm 
;		ld -m elf_i386 socket.o -o client

;

;Just some assigns for better readability
global _start
%include "constants.asm"
%include "util.asm"
%include "sockets.asm"

section .text
 
;--------------------------------------------------
;Functions to make things easier.
;--------------------------------------------------
 
send:
  ; Docstring: send a message across a socket
  ; ----
  ; Get the socket into a register...
  mov edx, [sock]
  ; send() take three argument: socket fd, data buffer to send, the size of said buffer, and some flags:
  ; sockfd
  mov [sArray + 0], edx
  ; data buffer (the data we're sending)
  mov [sArray + 4], eax
  ; length of the buffer
  mov [sArray + 8], ecx
  ; we don't want any flags...
  mov [sArray + 12], dword 0
  ; Call the socket API
  mov eax, SYS_socketcall
  mov ebx, SYS_SEND
  mov ecx, sArray
  int 0x80
  ret     

;--------------------------------------------------
;Main code body
;--------------------------------------------------
 
_start:
  ; Move the socket IP string to SI
  mov esi, szIp
  mov edi, sockaddr_in
  call initIP
  ; Move the port string to esi
  mov esi, szPort
  call initPort
  mov [sport], eax
 ; Move the socket port to si
  mov si, [sport]
  ; Create and connect to the socket
  call socket
  mov [sock], eax
  call connect
  ; If the connection failed for some reason, it'll return an error code (err != 0)
  cmp eax, 0
  ; If we had en error, call fail() to log it
  jnz fail
  ; Move the message we want to send to eax (and it's length to ecx)
	
fork:
	mov eax, SYS_FORK
	int 0x80
	cmp eax, 0
	jz recv

readInput:
  call userInput
  ; Send the message over the socket
  call send
  ; Thats it for today.
  jmp readInput

recv:
	; Docstring: Accept an incoming connection
	; Socketcall subcall: Recv (10)
	; The C syntax for this label is:
	; ssize_t recv(int s, void *buf, size_t len, int flags);
	; s - is the client's socket fd and it's int EAX, buf - data buffer to read into, size_t - how much to read, flags - nothing (0)
	; ----
	;
	; Move the socket fd (of the client) to edx
	;mov edx, [sock]
	; push the flags (nothing in our case)
	push 0
	; push the length of data to read from socket
	push 253
	; push the data buffer to read into
	push buffer
	; push the client's socket fd
	push dword [sock]
	; Move the pointer to recv() args into ECX and make the API call
	mov ecx, esp
	mov eax, SYS_socketcall
	mov ebx, SYS_RECV
	int 0x80
	cmp eax, -1
	jz fail
	cmp eax, 0
	jz exit
	mov edx, eax
	mov ecx, buffer
	call printOther
	jmp recv

printOther:
	; Docstring: Print the string in ecx (length stored in edx)
	; ----
	; Push the recived message and it's length to the stack
	push edx
	push ecx
	; Print the "Recived" label
	mov edx, otherlen
	mov ecx, otherPrompt
	mov ebx, stdout
	mov eax, SYS_WRITE
	int 0x80
	; Print the actual message
	pop ecx
	pop edx
	mov eax, SYS_WRITE
	int 0x80
	; Return for the normal input
	mov ecx, prompt
	mov edx, promptlen
	mov eax, SYS_WRITE
	int 0x80
	ret

fail:
  ; In case something wen't wrong, print an error msg and quit.
  mov edx, cerrlen
  mov ecx, cerrmsg
  call print
  call exit


_recverr: 
  call exit


_dced: 
  call exit


section .data
	%include "data.asm"
	; The error messsage if we couldn't connect
	cerrmsg      db 'failed to connect :(',0xa
	cerrlen      equ $-cerrmsg
	; The prompt text for getting input from the user
	 
	szIp         db '127.0.0.1',0
	szPort       db '43775',0
	 
section .bss
	; Allocate uninitialized memory the socket we're going to create
	sock         resd 1

	; I'm using cArray as a general 'array' for syscall_socketcall argument arg.
	cArray       resd 1
				 resd 1
				 resd 1
				 resd 1
	 
	; 'array' of things to send
	sArray      resd 1
				resd 1
				resd 1
				resd 1

	; sockaddr_in is a C struct used by the sockets API to store information about the socket (Address family, port and address)
	sockaddr_in resb 16

	; socket port
	sport       resb 2
	; data buffer
	buff        resb 1024
	buffer resb 254

	; The buffer to hold the user's data
	out_buff resb 256
