%macro	bind	3
	; Bind a server socket to a certin port and IPs
	; -- Here we are building the sockaddr struct --
	mov	dx, %1
	mov	byte [edi + 3], dl
	mov	byte [edi + 2], dh
	; push addrlen
	push	16
	; push sockaddr
	push	%2
	; Finnaly, push the socket fd from ESI
	push	dword [%3]
	; Move the pointer to bind() args into ECX and make the API call
	mov	ecx, esp
	add	esp, 4 * 3
	socketcall	SYS_BIND
%endmacro

%macro	listen	1
	; Set a server's socket to listen for incoming connections
	; %1 - Socket FD
	; The size of the queue allowed
	push	dword 1
	; The socket fd
	push	dword [%1]
	; Move the pointer to listen() args into ECX and make the API call
	mov	ecx, esp
	add	esp, 4 * 2
	socketcall	SYS_LISTEN
%endmacro

%macro	accept	3
	; Accept an incoming connection to a server's socket
	; %1 - addrlen
	; %2 - addr
	; %3 - Socket FD
	; push addrlen (0)
	push	dword %1
	; push addr (0 - NULL)
	push	dword %2
	; push sockfd
	push	dword [%3]
	; Move the pointer to accept() args into ECX and make the API call
	mov	ecx, esp
	add	esp, 4 * 3
	socketcall	SYS_ACCEPT
%endmacro

%macro	socketcall	1
	; Make a subcall for socket operations
	; %1 - Subcall
	mov	eax, SYS_socketcall
	mov	ebx, %1
	int	0x80
%endmacro
