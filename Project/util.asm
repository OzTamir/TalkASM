;--------------------------------------------------
;Utilities Functions to make things easier:
;	initIP(esi = IP string, edi = resd sockaddr) - Get a hex IP from IP string (ret: hex IP in edi)
;	initPort(esi = Port string) - Get hex port from Port string (ret: hex port in eax)
;	readText(ecx = empty buffer, edx = bytes to read) - Read input from user (ret: input in buffer, length recived in eax)
;	exit() - Finish the run and return control to the OS (ret: None)
;	print(ecx = buffer to print, edx = length of said buffer) - Print a data buffer to STDOUT
;--------------------------------------------------

initIP:
	; Docstring: Convert a IP string to hex format
	; Args: IP String at esi, empty buffer in edi
	; Returns: Hex IP in edi
	; ----
	xor eax,eax
	xor ecx,ecx
	xor edx,edx
	.clearCount:
		xor ebx, ebx
	.getChar:
		lodsb
		inc edx
		sub al, '0'
		jb  .next
		imul ebx, byte 10
		add ebx, eax
		jmp short .getChar
	.next:
		mov [edi + ecx + 4], bl
		inc ecx
		cmp ecx, byte 4
		jne .clearCount
	mov word [edi], AF_INET
	ret

initPort:
	; Docstring: Convert a Port string to hex format
	; Args: Port string at esi
	; Returns: Hex Port in eax
	; ----
	xor eax,eax
	xor ebx,ebx
	xor edx, edx
	.getChar:   
		lodsb      
		test al, al
		jz .end
		sub al, '0'
		imul ebx, 10
		add ebx, eax
		inc edx 
		jmp .getChar
	.end:
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

exit:
	; Docstring: Finish the run and return control to the OS
	; ----
	push 0x1
	mov eax, 1
	push eax
	int 0x80

print:
	; Docstring: Print a string
	; Args: String to print in ecx, it's length in edx
	; ----
	mov ebx, stdout
	mov eax, SYS_WRITE
	int 0x80
	ret