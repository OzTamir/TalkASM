; Remote shell - this code will setup a localhost server and will spawn a shell for
; 				 the connected socket
; Written by Oz Tamir with insparation from @arno01
;----------------
; Global note:
; The syntax for making a socketcall in C is:
; int socketcall(int call, unsigned long *args);
;
; Therefor, any socketcall will be carried out as described here:
; EAX - 102, the socketcall API number.
; EBX - The call we would like to preform (socket, bind, send and so on)
; ECX - The args for the specific call
; 
; This is the general syntax for socketcalls in this code, and to prevent redundency I will only
; explain the specific subcall when one is being made.
;----------------
global _start
%include "constants.asm"
%include "util.asm"
%include "sockets.asm"

section .text

_start:
	xor eax, eax
	
run_server:
	; Get the socket's fd in eax
	call socket
	; We store the socket's file descriptor in ESI for later
	mov esi, eax
	mov [sock], eax
	; Get the port number specified
	mov edi, serverPort

bind:
	; Docstring: Bind the socket we've created to the IP and port we'll supply.
	; Socketcall subcall: Bind (2)
	; The C syntax for this label is:
	; int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
	; (sockfd - stored in esi, sockaddr - {2 - AF_INET, 43775 - Port Number, 0 - host addr (0.0.0.0 means ANY host)},																			16 - length of an IPv4 addr)
	; ----
	mov eax, SYS_socketcall
	mov ebx, SYS_BIND
	; -- Here we are building the sockaddr struct --
	; Push 0.0.0.0 as host address
	xor edx, edx
	push edx
	; Push the port number
	push WORD [edi]
	; Push the address family, 2, using the fact that it's also the current socketcall call number. Neat, right?
	push WORD bx
	; -- Store the struct in ECX and push the remaining args.
	mov ecx, esp
	; push addrlen
	push BYTE 16
	; push sockaddr
	push ecx
	; Finnaly, push the socket fd from ESI
	push esi
	; Move the pointer to bind() args into ECX and make the API call
	mov ecx, esp
	int 0x80

listen:
	; Docstring: Set listening mode and wait for incoming connections
	; Socketcall subcall: Listen (4)
	; The C syntax for this label is:
	; int listen(int s, int backlog);  
	; s - the socket fd, backlog - the number of queue allowed
	; ----
	;
	mov BYTE al, SYS_socketcall
	mov ebx, SYS_LISTEN
	; The size of the queue allowed
	push BYTE 10
	; The socket fd
	push esi
	; Move the pointer to listen() args into ECX and make the API call
	mov ecx, esp
	int 0x80

accept:
	; Docstring: Accept an incoming connection
	; Socketcall subcall: Accept (5)
	; The C syntax for this label is:
	; int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
	; sockfd - still in good ol' ESI, addr is set to NULL since we don't care who the client is, addrlen is ignored since addr is NULL.
	; ----
	;
	mov BYTE al, SYS_socketcall
	mov ebx, SYS_ACCEPT
	; push addrlen (0)
	push edx
	; push addr (0 - NULL)
	push edx
	; push sockfd
	push esi
	; Move the pointer to accept() args into ECX and make the API call
	mov ecx, esp
	int 0x80
	mov [sock], eax

fork:
	; Docstring: Fork the process to emulate multithreading
	; ----
	mov eax, SYS_FORK
	int 0x80
	; If the return value is 0, we are in the child process
	cmp eax, 0
	jz readInput

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
	jz exit
	cmp eax, 0
	jz recv
	
	mov esi, buffer
	push eax
	call cmpstr
	cmp eax, 0
	je recvExit
	pop eax
	
	mov edx, eax
	mov ecx, buffer
	call printOther
	jmp recv

readInput:
	; Get input from user
	call userInput
	; Move the socket's fd to edx
	mov edx, [sock]
	; Send it!
	call send
	
	;Check if the user want to quit
	mov esi, out_buff
	call cmpstr
	cmp eax, 0
	je exit
	
	jmp readInput
  
section .data
	%include "data.asm"

section .bss
	; The socket's file descriptor
	sock resd 1
	bind_addr resb 16
	; The input and output buffers
	buffer resb 254
	out_buff resb 256
