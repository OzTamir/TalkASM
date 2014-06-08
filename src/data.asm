; Output prompts
otherPrompt	db	0, 'Recived: '
otherlen	equ	$-otherPrompt
prompt	db	'>> '
promptlen	equ	$-prompt

; The error messsage if we couldn't connect
cerrmsg	db	'failed to connect :(',0
cerrlen	equ	$-cerrmsg

; Usage errors
clientUse	db	'ERROR!', 0xa, 'Usage: ./client <Server IP> <PORT>', 0
c_usagelen	equ	$-clientUse

; Port settings
serverPort	db	0xaa, 0xff
clientPort	db	'43775',0

; Exit settings
exitSTR	db	'The other side has closed the connection.', 0
exitLen	equ	$-exitSTR

; GUI IDs
newString	szGladeFile, 'chat.glade'
newString	szIDMainWin, 'mWin'
newString	szIDMainGrid, 'mGrid'
newString	szIDSubGrid, 'sGrid'
newString	szIDchatView, 'chatView'
newString	szIDEntry, 'entry'
newString	szIDSendBtn, 'send'
newString	szEmptyString, ''
