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

; Port settings
;~ serverPort	db 0xaa, 0xff
clientPort db '43775',0

; Exit settings
exitSTR db 'exit', 0xa
exitLen equ $-exitSTR
