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

_bind:
  ; Docstring: Bind the server to a certin port
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
  mov ebx, SYS_BIND
  mov ecx, cArray
  int 0x80
  ret
  
_listen:
  ; Docstring: Listen and accept incoming connections
  ; ----
;  call _bind
  ; Push the listen() parameters into stack - queue length and then socket fd
  mov eax, [sock]
  mov [lArray + 0], eax
  mov [lArray + 4], dword 20
  mov		eax, SYS_socketcall
  mov		ebx, SYS_LISTEN
  mov		ecx, lArray
  int		0x80
  ret
  
 _accept:
  ; Docstring: Listen and accept incoming connections
  ; ----
  call _listen
  cmp eax, 0
  jnz _fail
  mov eax, [sock]
  mov dx, si
  mov byte [edi + 3], dl
  mov byte [edi + 2], dh
  
  mov [sArray + 0], eax
  ; sockaddr
  mov [sArray + 4], edi
  ; length of the buffer
  mov [sArray + 8], dword 16

  mov		eax, SYS_socketcall
  mov		ebx, SYS_ACCEPT
  mov		ecx, esp
  int		0x80
  ret

_recv:
  call _accept
  ;mov [sArray + 0], eax
  ; data buffer (the data we're sending)
  ;mov [sArray + 4], ecx
  ; length of the buffer
  ;mov [sArray + 8], edx
  ; we don't want any flags...
  ;mov [sArray + 12], dword 0
  mov		eax, SYS_READ
  mov		ebx, [sock]
  lea ecx, [msg]
  mov edx,  256
  int		0x80
  ret
 
_exit:
  ; Docstring: Finish the run and return control to the OS
  ; ----
  push 0x1
  mov eax, 1
  push eax
  int 0x80
 
_print:
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
  ; Create and connect to the socket
  call _bind
  ; If the connection failed for some reason, it'll return an error code (err != 0)
  cmp eax, 0
  ; If we had en error, call fail() to log it
  jnz short _fail
  ; Move the message we want to send to eax (and it's length to ecx)
  jmp _readInput


_readInput:
  ; Docstring: Read an input from the user and send it over the socket
  ; ----
  ; Prompt the user for input
  ;mov  ecx,prompt
  ;mov  edx,promptlen	
  ;call _print
  mov si, [sport]
  call _recv
  mov edx,eax
  call _print
  ; Thats it for today.
  call _exit


_fail:
  ; In case something wen't wrong, print an error msg and quit.
  mov edx, cerrlen
  mov ecx, cerrmsg
  call _print
  call _exit


_recverr: 
  call _exit


_dced: 
  call _exit


section .data
; The error messsage if we couldn't connect
cerrmsg      db 'failed to connect :(',0xa
cerrlen      equ $-cerrmsg
; The prompt text for getting input from the user
prompt          db 'Enter your message:',0xa
promptlen       equ $-prompt
 
szIp         db '127.0.0.1',0
szPort       db '1728',0
 
section .bss
; Allocate uninitialized memory the socket we're going to create
sock         resd 1

lArray        resd 1
			  resd 1
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

socket_address resd 1

; socket port
sport       resb 2
; data buffer
buff        resb 1024

; The buffer to hold the user's data
msg resb 256
