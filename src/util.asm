;--------------------------------------------------
;Utilities Functions to make things easier:
;	initIP(esi = IP string, edi = resd sockaddr) - Get a hex IP from IP string (ret: hex IP in edi)
;	initPort(esi = Port string) - Get hex port from Port string (ret: hex port in eax)
;	readText(ecx = empty buffer, edx = bytes to read) - Read input from user (ret: input in buffer, length recived in eax)
;	exit() - Finish the run and return control to the OS (ret: None)
;	print(ecx = buffer to print, edx = length of said buffer) - Print a data buffer to STDOUT
;--------------------------------------------------

initIP:
	; Docstring: Convert a IP string to int format
	; Args: IP String at esi, empty buffer in edi
	; Returns: Hex IP in edi
	; ----
	; Clear the registers we're using
	xor eax,eax
	xor ecx,ecx
	xor edx,edx
	.clearCount:
		xor ebx, ebx
	.getChar:
		; Load a byte from the string in ESI into AL
		lodsb
		; Increase the counter
		inc edx
		; Normalize it
		sub al, '0'
		jb  .next
		; This has to do with base convartion
		imul ebx, byte 10
		; Add the char to ebx
		add ebx, eax
		jmp short .getChar
	.next:
		; Add the recived byte to edi + offset
		mov [edi + ecx + 4], bl
		; Increase the counter
		inc ecx
		; Check if we've read enough
		cmp ecx, byte 4
		; If not, keep going
		jne .clearCount
	; Add the address family identifier to the end of the buffer
	mov word [edi], AF_INET
	ret

initPort:
	; Docstring: Convert a Port string to int format
	; Args: Port string at esi
	; Returns: Hex Port in eax
	; ----
	; Clear the registers we're using
	xor eax,eax
	xor ebx,ebx
	xor edx, edx
	.getChar:
		; Load a byte from the string at ESI
		lodsb
		; Check if there's nothing to read (al == 0)
		test al, al
		jz .end
		; Normalize the char
		sub al, '0'
		; Base convarsion
		imul ebx, 10
		; Add the char to ebx
		add ebx, eax
		; Increase the counter
		inc edx
		; Loop
		jmp .getChar
	.end:
		; As per calling convantions, return value is to be stored within EAX
		xchg ebx, eax   
	ret

readText:
	; Docstring: Read input from the user
	; Args: Buffer to write into in ecx, number of bytes to read at edx
	; Returns: Number of bytes read in eax, data read in passed buffer
	; ----
	mov eax, SYS_READ
	mov ebx, stdin
	int 0x80
	ret

print:
	; Docstring: Print a string
	; Args: String to print in ecx, it's length in edx
	; ----
	mov ebx, stdout
	mov eax, SYS_WRITE
	int 0x80
	ret
