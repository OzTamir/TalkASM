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
%assign SYS_FORK			2
%assign SOCK_STREAM         1
%assign AF_INET             2
%assign SYS_socketcall      102
%assign SYS_SOCKET          1
%assign SYS_BIND			2
%assign SYS_CONNECT         3
%assign SYS_LISTEN			4
%assign SYS_ACCEPT			5
%assign SYS_SEND            9
%assign SYS_RECV            10
%assign SYS_READ			3
%assign SYS_WRITE           4
%assign stdout           	1
%assign stdin				0

global _start
section .text

_start:
	xor eax, eax
	
socket:
	; Docstring: Create a socket file descriptor
	; The C syntax for this label is:
	; int socket(int domain, int type, int protocol);
	; domain = 6(IPPROTO_TCP), type = 1(SOCK_STREAM), protocol = 2(AF_INET)
	; ----
	;
	mov al, SYS_socketcall
	mov ebx, SYS_SOCKET
	; socket() args pushed to the stack (LIFO order):
	;	6 -> IPPROTO_TCP (TCP Protocol)
	;	1 -> SOCK_STREAM (Socket protocol to support the TCP)
	;	2 -> AF_INET (We tell the system API that we want socket from the internet address family, IPv4 as example)
	push BYTE 6
	push BYTE 1
	push BYTE 2
	; Now we put the pointer to the socket() args we just pushed into ECX
	mov ecx, esp
	int 0x80
	; We store the socket's file descriptor in ESI for later
	mov esi, eax
	mov [sock], eax

run_server:
	; Get the port number specified
	mov edi, port

bind:
	; Docstring: Bind the socket we've created to the IP and port we'll supply.
	; Socketcall subcall: Bind (2)
	; The C syntax for this label is:
	; int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
	; (sockfd - stored in esi, sockaddr - {2 - AF_INET, 43775 - Port Number, 0 - host addr (0.0.0.0 means ANY host)},																			16 - length of an IPv4 addr)
	; ----
	;
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
	mov edx, [sock]
	mov eax, SYS_socketcall
	mov ebx, SYS_RECV
	; push the flags (nothing in our case)
	push 0
	; push the length of data to read from socket
	push 253
	; push the data buffer to read into
	push buffer
	; push the client's socket fd
	push edx
	; Move the pointer to recv() args into ECX and make the API call
	mov ecx, esp
	int 0x80
	cmp eax, -1
	jz exit
	cmp eax, 0
	jz recv
	mov edx, eax
	mov ecx, buffer
	call printOther
	jmp recv

readInput:
	; Docstring: Recive an input from the user and send it
	; ----
	; Print the prompt (">> ")
	mov edx, promptlen
	mov ecx, prompt
	call print
	; Read input
	mov ecx, out_buff
	mov edx, 256
	call readText
	; Move the input to eax and the length to ecx
	push eax
	mov eax, out_buff
	pop ecx
	; Move the socket's fd to edx
	mov edx, [sock]
	; Send it!
	jmp send

readText:
	; Docstring: A small subroutine to read input
	mov eax, SYS_READ
	mov ebx, stdin
	int 0x80
	ret

send:
	; Docstring: Send the buffer stored in eax over the socket
	; C-syntax: ssize_t send(int s, const void *buf, size_t len, int flags);
	; ----
	;
	; Push the flags (none)
	push dword 0
	; Push the length (we stored it in ecx on 'readInput'
	push ecx
	; Push the data itself
	push eax
	; Push the socket's fd
	push edx
	; Move the arguments to ecx
	mov ecx, esp
	; Make the system call
	mov eax, SYS_socketcall
	mov ebx, SYS_SEND
	int 0x80
	; Jump to read new input in an infinite loop
	jmp readInput

print:
	; Docstring: Print the string in ecx (length stored in edx)
	; ----
	mov ebx, stdout
	mov eax, SYS_WRITE
	int 0x80
	ret

printOther:
	; Docstring: Print the data recived from the socket (preceded by "Recived: " label)
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
	; Return the prompt of the normal input
	mov ecx, prompt
	mov edx, promptlen
	mov eax, SYS_WRITE
	int 0x80
	ret

exit:
  ; Docstring: Finish the run and return control to the OS
  ; ----
  push 0x1
  mov eax, 1
  push eax
  int 0x80
  
section .data
	; Our port number in hex format
	port	db 0xaa, 0xff
	; Output prompts
	otherPrompt db 0xa, 'Recived: '
	otherlen equ $-otherPrompt
	prompt db '>> '
	promptlen equ $-prompt

section .bss
	; The socket's file descriptor
	sock resd 1
	; The input and output buffers
	buffer resb 254
	out_buff resb 256
