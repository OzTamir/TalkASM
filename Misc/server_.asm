global _start

section .text

	_start:

;------------------------------------------
;socket()

push 	dword        6
push	dword	1	
push	dword	2

;system call socket

mov		eax, 102
mov		ebx, 1
mov		ecx, esp

int		0x80

;------------------------------------------

section .bss

socket:		resd	1
connection:		resd	1
socket_address:	resd	2

;------------------------------------------

section	.text

mov	Dword [socket],eax

;------------------------------------------
;sockaddr

push	qword	0
push	dword	0x2717155E ; network byte order
push	word	0x5000	;network byte order
push	word	2

;pointer to sockaddr

mov	[socket_address],esp

;bind()

push	dword	16
push 	dword	[socket_address]
push 	dword [socket]

;systemcall bind()

mov		eax, 102
mov		ebx, 2
mov		ecx, esp

int		0x80

;------------------------------------------
;listen()

push	byte	20
push 	dword [socket]

;systemcall listen()

mov		eax, 102
mov		ebx, 4
mov		ecx, esp

int		0x80
;------------------------------------------
;accept()

push 0
push 0
push dword [socket]

;systemcall accept()

mov		eax, 102
mov		ebx, 5
mov		ecx, esp

int		0x80
