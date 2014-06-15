global	main

; Include the other source files
%include	"constants.asm"
%include	"util.asm"
%include	"sockets.asm"
%include	"macros.asm"
%include	"GUIMacros.asm"

; Include the Gtk functions that we'll use 
extern	gtk_init, gtk_builder_new, gtk_builder_add_from_file, gtk_builder_get_object, exit
extern	gtk_builder_connect_signals, g_object_unref, gtk_widget_show, gtk_main, gtk_widget_destroy
extern	gtk_main_quit, g_signal_connect_data, gtk_text_view_set_buffer, gtk_text_buffer_set_text
extern	gtk_entry_set_text, gtk_entry_get_text, gtk_entry_get_text_length, gtk_widget_hide, gtk_dialog_run

; Include the GLib functions that we'll use 
extern	g_io_add_watch, g_io_channel_unix_new, g_timeout_add

; Include the functions from util.c
extern	gtk_text_view_append, AddTextToBuffer

; Initialized data declaration
section .data
	; Include the data source file
	%include	"data.asm"
	; GUI IDs
	newString	szIDDialog,	'clientDialog'
	newString	szIDipEntry,	'ipEntry'
	newString	szIDPortEntry,	'portEntry'
	newString	szIDConnectBtn,	'connectBtn'
	
	; GUI Events
	szevent_delete	db	"delete-event", 0
	szevent_destroy	db	"destroy", 0
	szevent_clicked	db	"clicked", 0

; Uninitialized data declaration
section .bss
	; GUI Data
	oBuilder	resd	1
	oMain	resd	1
	oMainGrid	resd	1
	oChatView	resd	1
	oSubGrid	resd	1
	oEntry	resd	1
	oSendBtn	resd	1
	oTextBuffer	resd	1
	oText	resd	1
		
	; Welcome Dialog Widgets
	oDialog	resd	1
	oDialogBtns	resd	1
	oDialogGrid	resd	1
	oTitle	resd	1
	oIPGrid	resd	1
	oIPLbl	resd	1
	oIPEntry	resd	1
	oPortEntry	resd	1
	oConnectBtn	resd	1
		
	; Socket data
	sock	resd	1
	sockaddr_in	resb	16
	port	resb	2
	buffer	resb	254
	out_buff	resb	256
	
	sockChannel	resd 1
	
; Actual Code
section .text
main:
	; Call gtk_init with no arguments
	push	0 
	push	0
	call	gtk_init
	add	esp, 4 * 2   
	
	; Get a GtkBuilder object
	call	gtk_builder_new
	mov	[oBuilder], eax
	
	; Load Glade File into our GtkBuilder
	push	NULL  
	push	szGladeFile
	push	eax 
	call	gtk_builder_add_from_file
	add	esp, 4 * 3 
	
	; Add the GUI widgets
	; Add the dialog widget
	addWidget	oBuilder, szIDDialog, oDialog
	
	; Add the IP text entry
	addWidget	oBuilder, szIDipEntry, oIPEntry
	
	; Add the Port text entry
	addWidget	oBuilder, szIDPortEntry, oPortEntry
	
	; Add the 'Connect' Button
	addWidget	oBuilder, szIDConnectBtn, oConnectBtn
	
	; Add The Top-Level Window
	addWidget	oBuilder, szIDMainWin, oMain
	
	; Add the Main Grid
	addWidget	oBuilder, szIDMainGrid, oMainGrid
	
	; Add the Text View to display the chat in
	addWidget	oBuilder, szIDchatView, oChatView
	
	; Add the grid to contain the entry and send button
	addWidget	oBuilder, szIDSubGrid, oSubGrid
	
	; Add the text entry widget
	addWidget	oBuilder, szIDEntry, oEntry
	
	; Add the send button
	addWidget	oBuilder, szIDSendBtn, oSendBtn
	
	; Connect the signals
	push	dword [oBuilder]  
	call	gtk_builder_connect_signals
	add	esp, 4 * 1
	
	; GUI events
	; Call 'event_delete' in case oMain is deleted
	addEvent	event_delete, szevent_delete, oMain
	
	; Call 'event_destroy' in case oMain is destroyed
	addEvent	event_destroy, szevent_destroy, oMain
	
	; Call 'send_click' in case oSendBtn is clicked
	addEvent	send_click, szevent_clicked, oSendBtn
	
	; Call 'connect_click' in case oConnectBtn is pressed
	addEvent	connect_click, szevent_clicked, oConnectBtn
	
	; Remove the refrence to the GtkBuilder (We won't need it anymore)
	push	dword [oBuilder]
	call	g_object_unref 
	add	esp, 4 * 1   
	
	; Run the Welcome Dialog
	push	dword [oDialog]
	call	gtk_dialog_run
	add	esp, 4 * 1
	
	; Start the main Gtk Loop
	call	gtk_main
	ret
	
; Setup the chat backend
setup_client:
	; Create a socket
	mov	[port], eax
	call	socket
	mov	[sock], eax
	; Connect to socket
	mov	si, [port]
	call	connect
	
	; Get a GIOChannel from the socket's FD
	push	dword [sock]
	call	g_io_channel_unix_new
	add	esp, 4*1
	
	; Watch the socket for I/O
	push	NULL
	push	recv
	;We want G_IO_IN condition - call recv when data is available to read
	push	1
	push	eax
	call	g_io_add_watch
	add	esp, 4 * 4
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
	push	0
	; push the length of data to read from socket
	push	253
	; push the data buffer to read into
	push	buffer
	; push the client's socket fd
	push	dword [sock]
	; Move the pointer to recv() args into ECX and make the API call
	mov	ecx, esp
	add	esp, 4 * 4
	mov	eax, SYS_socketcall
	mov	ebx, SYS_RECV
	int	0x80
	
	; Append the recived data to the text view
	push	buffer
	push	dword [oChatView]
	call	AddTextToBuffer
	add	esp, 4 * 2
	
	; Return true to avoid infinite loop
	mov	eax, 1
	ret

; This is what happend when the 'connect' button on the welcome screen is pressed
connect_click:
	; Get the IP from the text entry
	push	dword [oIPEntry]
	call	gtk_entry_get_text
	add	esp, 4 * 1
	mov	esi, eax
	mov	edi, sockaddr_in
	call	initIP
	
	; Get the port number from the text entry
	push	dword [oPortEntry]
	call	gtk_entry_get_text
	add	esp, 4 * 1
	mov	esi, eax
	call	initPort
	
	; Setup the chat
	call	setup_client
	
	; Hide the welcome screen
	push	dword [oDialog]
	call	gtk_widget_hide
	add	esp, 4 * 1
	
	; Load the chat screen
	push	dword [oMain]
	call	gtk_widget_show
	add	esp, 4 * 1
	ret
	
; This is what happens when the user quit
event_delete:
	; Send an exit string to inform the other side that you've quited
	mov	ecx, exitLen
	mov	eax, exitSTR
	mov	edx, [sock]
	call	send
	
	; Quit the GUI
	call	gtk_main_quit
	call	exit
	ret     

; This is what happend when the GUI is destroyed
event_destroy:    
	call	gtk_main_quit
	ret

; This is what happend when the 'send' button on the chat screen get clicked
send_click:
	; Get the length of the user's message
	push	dword [oEntry]
	call	gtk_entry_get_text_length
	add	esp, 4 * 1
	mov	ecx, eax
	
	; Get the actual message
	push	dword [oEntry]
	call	gtk_entry_get_text
	add	esp, 4 * 1
	
	; Send the message over the socket
	mov	edx, [sock]
	call	send
	
	; Add the message to the chat view
	push	dword [oEntry]
	push	dword [oChatView]
	call	gtk_text_view_append
	add	esp, 4 * 2
	
	; Clean the text entry field
	push	szEmptyString
	push	dword [oEntry]
	call	gtk_entry_set_text
	add	esp, 4 * 2
	ret
