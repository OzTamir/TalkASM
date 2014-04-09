; TalkASM - Simple Chat Written By OzTamir (Server)
;--------------------------------------------------
global _start
%include "constants.asm"
%include "util.asm"
%include "sockets.asm"

section .text
_start:
	; Get the CLI arguments and parse it
	pop ebx
	; Verify that we got the expected number of arguments
	cmp ebx, 2
	jnz clientUsage
	; Get the IP argument
	pop ecx
	pop ecx
	mov esi, ecx
	mov edi, sockaddr_in
	call initIP
	; Get the Port argument
	mov esi, clientPort
	call initPort
	mov [port], eax

start_client:
	; Create and connect to the socket
	call socket
	mov [sock], eax
	mov si, [port]
	call connect
	; If the connection failed for some reason, notify the user
	cmp eax, 0
	jnz fail
	
fork:
	; Fork the two processes (Reading from the Terminal and reciving from the socket)
	mov eax, SYS_FORK
	int 0x80
	cmp eax, 0
	jz recv

readInput:
	; Get input from the user
	call userInput
	; Send the message over the socket
	mov edx, [sock]
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

section .data
	%include "data.asm"
	 
section .bss
	; Allocate uninitialized memory the socket we're going to create
	sock         resd 1
	; sockaddr_in is a C struct used by the sockets API to store information about the socket (Address family, port and address)
	sockaddr_in resb 16
	; socket port
	port       resb 2
	; data buffer
	buffer resb 254
	; The buffer to hold the user's data
	out_buff resb 256
