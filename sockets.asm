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
	; Call the socket API
	int 0x80
	; Align the stack to avoid seg. fault
	pop ebp
	pop ebp
	pop ebp
	ret

userInput:
	; Docstring: Read an input from the user and send it over the socket
	; ----
	; Prompt the user for input
	mov ecx,prompt
	mov edx,promptlen	
	call print
	; Buffer to save input in
	mov  ecx, out_buff
	; Number of bytes to read
	mov edx, 256
	call readText
	; Push the return value (the input length) to stack
	push eax
	; Move the input itself to eax
	mov eax, out_buff
	; Pop the msg length into ecx
	pop ecx
	ret

;--------------------------------------------------
; Server Functions:
;--------------------------------------------------


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
  mov byte [edi + 3], dl
  mov byte [edi + 2], dh
  ; We are now calling connect, which takes three arguments: socket fd, pointer to sockaddr and the length of sockaddr.
  ; We will store those arguments in a 'array' and then call the interrupt:
  push 16
  push edi
  push eax
  mov ecx, esp
  ; Call the connect interrupt with the data we provided.
  mov eax, SYS_socketcall
  mov ebx, SYS_CONNECT
  int 0x80
  ; Align the stack
  pop ebp
  pop ebp
  pop ebp
  ret
