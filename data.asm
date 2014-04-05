; Output prompts
otherPrompt db 0xa, 'Recived: '
otherlen equ $-otherPrompt
prompt db '>> '
promptlen equ $-prompt

; The error messsage if we couldn't connect
cerrmsg      db 'failed to connect :(',0xa
cerrlen      equ $-cerrmsg

; Usage errors
clientUse      db 'ERROR!', 0xa, 'Usage: ./client <Server IP> <PORT>', 0xa
c_usagelen      equ $-clientUse
serverUse      db 'ERROR!', 0xa, 'Usage: ./server <PORT>', 0xa
s_usagelen      equ $-serverUse
