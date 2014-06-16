;--------------------------------------------------
; Common Functions:
;--------------------------------------------------
socket:
	; Docstring: Create a socket file descriptor
	; The C syntax for this label is:
	; int socket(int domain, int type, int protocol);
	; domain = 6(IPPROTO_TCP), type = 1(SOCK_STREAM), protocol = 2(AF_INET)
	; ----
	;
	mov eax, SYS_socketcall
	mov ebx, SYS_SOCKET
	; socket() args pushed to the stack (LIFO order):
	;	6 -> IPPROTO_TCP (TCP Protocol)
	;	1 -> SOCK_STREAM (Socket protocol to support the TCP)
	;	2 -> AF_INET (We tell the system API that we want socket from the internet address family, IPv4 as example)
	push BYTE IPPROTO_TCP
	push BYTE SOCK_STREAM
	push BYTE AF_INET
	mov ecx, esp
	add esp, 4 * 3
	; Call the socket API
	int 0x80
	; Align the stack to avoid seg. fault
	ret

send:
	; Docstring: Send the buffer stored in eax over the socket
	; C-syntax: ssize_t send(int s, const void *buf, size_t len, int flags);
	; ----
	;
	; Push the flags (none)
	push dword 0
	; Push the length
	push ecx
	; Push the data itself
	push eax
	; Push the socket's fd
	push edx
	; Move the arguments to ecx
	mov ecx, esp
	add esp, 4 * 4
	; Make the system call
	mov eax, SYS_socketcall
	mov ebx, SYS_SEND
	int 0x80
	ret


;--------------------------------------------------
; Client Functions:
;--------------------------------------------------
connect:
	; Docstring: Connect to the socket
	; Args: Socket fd in eax, Hex port in esi
	; Return: 0 on succsess, error code otherwise
	; ----
	; Get the pointer to the socket address (sockaddr) from the source register (SI)
	mov dx, si
	; This has to do with the definition of the sockaddr_in structure
	; To understand the offset, see initIP at 'util.asm'
	; Notice how we always move the IP chars to [edi + 4]
	; We don't use [edi + 1] as a starting point because we need to pad the sockaddr_in with zeros
	mov byte [edi + 3], dl
	mov byte [edi + 2], dh
	; We are now calling connect, which takes three arguments: socket fd, pointer to sockaddr and the length of sockaddr.
	; We will store those arguments in a 'array' and then call the interrupt:
	push 16
	push edi
	push eax
	mov ecx, esp
	add esp, 4 * 3
	; Call the connect interrupt with the data we provided.
	mov eax, SYS_socketcall
	mov ebx, SYS_CONNECT
	int 0x80
	ret
