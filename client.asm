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

%assign SYS_FORK			2
%assign SOCK_STREAM         1
%assign AF_INET             2
%assign SYS_socketcall      102
%assign SYS_SOCKET          1
%assign SYS_CONNECT         3
%assign SYS_SEND            9
%assign SYS_RECV            10
%assign SYS_READ			3
%assign SYS_WRITE           4
%assign stdout           	1
%assign stdin				0
 
section .text
  global _start
 
;--------------------------------------------------
;Functions to make things easier.
;--------------------------------------------------
_socket:
  ; Docstring: Create a Socket from the data found in cArray and return the socket's file descriptor
  ; ----
  ;Our socket's address's family - Internet Protocol, in this case
  mov [cArray + 0], dword AF_INET
  ; Stream protocol - TCP Here
  mov [cArray + 4], dword SOCK_STREAM
  mov [cArray + 8], dword 0
  ; Call the socket API
  mov eax, SYS_socketcall
  mov ebx, SYS_SOCKET
  mov ecx, cArray
  int 0x80
  ret
 
_connect:
  ; Docstring: Connect to the socket
  ; ----
  ; Get a socket
  call _socket
  ; Move the socket fd recived into sock
  mov dword [sock], eax
  ; Get the pointer to the socket address (sockaddr) from the source register (SI)
  mov dx, si
  mov byte [edi + 3], dl
  mov byte [edi + 2], dh
  ; We are now calling connect, which takes three arguments: socket fd, pointer to sockaddr and the length of sockaddr.
  ; We will store those arguments in a 'array' and then call the interrupt:
  ; sockfd
  mov [cArray + 0], eax
  ; &sockaddr_in
  mov [cArray + 4], edi
  ; 16 is the length for IPv4. This is equal to sizeof(sockaddr_in) in C
  mov edx, 16
  mov [cArray + 8], edx
  ; Call the connect interrupt with the data we provided.
  mov eax, SYS_socketcall
  mov ebx, SYS_CONNECT
  mov ecx, cArray
  int 0x80
  ret
 
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
 
exit:
  ; Docstring: Finish the run and return control to the OS
  ; ----
  push 0x1
  mov eax, 1
  push eax
  int 0x80
 
print:
  ; Docstring: Print the string in edx (length stored in ecx)
  ; ----
  mov ebx, stdout
  mov eax, SYS_WRITE
  int 0x80   
  ret         

;--------------------------------------------------
;Main code body
;--------------------------------------------------
 
_start:
  ; Move the socket IP string to SI
  mov esi, szIp
  ; Move the uninitialized sockaddr_in to edi
  mov edi, sockaddr_in
  ; Clear EAX, ECX, EDX
  xor eax,eax
  xor ecx,ecx
  xor edx,edx
  ; Initialize sockaddr_in
  .cc:
    xor   ebx,ebx
  .c:
    lodsb
    inc   edx
    sub   al,'0'
    jb   .next
    imul ebx,byte 10
    add   ebx,eax
    jmp   short .c
  .next:
    mov   [edi + ecx + 4],bl
    inc   ecx
    cmp   ecx,byte 4
    jne   .cc
  ; Move the desired address family to edi
  mov word [edi], AF_INET
  ; Move the port string to esi
  mov esi, szPort 
  xor eax,eax
  xor ebx,ebx
  ; Initialize sport
  .nextstr1:   
    lodsb      
    test al,al
    jz .ret1
    sub   al,'0'
    imul ebx,10
    add   ebx,eax   
    jmp   .nextstr1
  .ret1:
    xchg ebx,eax   
    mov [sport], eax
 ; Move the socket port to si
  mov si, [sport]
  ; Create and connect to the socket
  call _connect
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
  ; Docstring: Read an input from the user and send it over the socket
  ; ----
  ; Prompt the user for input
  mov ecx,prompt
  mov edx,promptlen	
  call print
  ; Buffer to save input in
  mov  ecx, msg
  ; Number of bytes to read
  mov edx, 256
  call readText
  ; Push the return value (the input length) to stack
  push eax
  ; Move the input itself to eax
  mov eax, msg
  ; Pop the msg length into ecx
  pop ecx
  ; Send the message over the socket
  call send
  ; Thats it for today.
  jmp readInput
  
readText:
	mov eax, SYS_READ
	mov ebx, stdin
	int 0x80
	ret

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
; The error messsage if we couldn't connect
cerrmsg      db 'failed to connect :(',0xa
cerrlen      equ $-cerrmsg
; The prompt text for getting input from the user
prompt          db '>> '
promptlen       equ $-prompt
otherPrompt db 0xa, 'Recived: '
otherlen equ $-otherPrompt
 
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
msg resb 256
