global main

%include "constants.asm"
%include "util.asm"
%include "sockets.asm"

%assign NULL 0

;GTK
extern  gtk_init, gtk_builder_new, gtk_builder_add_from_file, gtk_builder_get_object
extern gtk_builder_connect_signals, g_object_unref, gtk_widget_show_all, gtk_main
extern gtk_main_quit, g_signal_connect_data, gtk_text_view_set_buffer, gtk_text_buffer_set_text
extern gtk_entry_set_text, gtk_entry_get_text, gtk_entry_get_text_length

extern g_io_add_watch, g_io_channel_unix_new, g_timeout_add

;Own functions
extern gtk_text_view_append, AddTextToBuffer

section .data
	%include "data.asm"
	; GUI IDs
    szGladeFile db 'chat.glade', 0
    szIDMainWin db 'mWin', 0
    szIDMainGrid db 'mGrid', 0
    szIDchatView db 'chatView', 0
    szIDSubGrid db 'sGrid', 0
    szIDEntry db 'entry', 0
    szIDSendBtn db 'send', 0
    szEmptyString db '', 0
    
    ; Events
    szevent_delete      db  "delete-event", 0
	szevent_destroy     db  "destroy", 0
	szevent_clicked     db  "clicked", 0
	
	localhost db '127.0.0.1', 0


section .bss
    oBuilder resd 1
    oMain resd 1
    oMainGrid resd 1
    oChatView resd 1
    oSubGrid resd 1
    oEntry resd 1
    oSendBtn resd 1
    oTextBuffer resd 1
    oText resd 1
    
    ; Allocate uninitialized memory the socket we're going to create
	sock         resd 1
	; sockaddr_in is a C struct used by the sockets API to store information about the socket (Address family, port and address)
	sockaddr_in resb 16
	; socket port
	port       resb 2
	; data buffer
	buffer resb 254
	; The buffer to hold the user's data
	out_buff resb 256
	
	sockChannel resd 1

section .text
main:     
    push    0 
    push    0
    call    gtk_init
    add     esp, 4 * 2   
    
    call    gtk_builder_new
    mov     [oBuilder], eax
        
    push    NULL  
    push    szGladeFile
    push    eax 
    call    gtk_builder_add_from_file
    add     esp, 4 * 3 
    
    push    szIDMainWin
    push    dword [oBuilder]
    call    gtk_builder_get_object 
    add     esp, 4 * 2
    mov     [oMain], eax
    
    push    szIDMainGrid
    push    dword [oBuilder]
    call    gtk_builder_get_object
    add     esp, 4 * 2
    mov     [oMainGrid], eax
    
    push    szIDchatView
    push    dword [oBuilder]
    call    gtk_builder_get_object
    add     esp, 4 * 2
    mov     [oChatView], eax

    push    szIDSubGrid
    push    dword [oBuilder]
    call    gtk_builder_get_object
    add     esp, 4 * 2
    mov     [oSubGrid], eax

    push    szIDEntry
    push    dword [oBuilder]
    call    gtk_builder_get_object
    add     esp, 4 * 2
    mov     [oEntry], eax
    
    push    szIDSendBtn
    push    dword [oBuilder]
    call    gtk_builder_get_object
    add     esp, 4 * 2
    mov     [oSendBtn], eax

    push    dword [oBuilder]  
    call    gtk_builder_connect_signals
    add     esp, 4 * 1
    
    ;Signals
    push    NULL
    push    NULL
    push    NULL
    push    event_delete
    push    szevent_delete
    push    dword [oMain]
    call    g_signal_connect_data
    add     esp, 4 * 6
    
    push    NULL
    push    NULL
    push    NULL
    push    event_destroy
    push    szevent_destroy
    push    dword [oMain]
    call    g_signal_connect_data
    add     esp, 4 * 6
        
    push    NULL
    push    NULL
    push    NULL
    push    event_clicked
    push    szevent_clicked
    push    dword [oSendBtn]
    call    g_signal_connect_data
    add     esp, 4 * 6
    
    push    dword [oBuilder]
    call    g_object_unref 
    add     esp, 4 * 1   

    push    dword [oMain]
    call    gtk_widget_show_all
    add     esp, 4 * 1
    
    call 	setup_client
    call    gtk_main
    ret

setup_client:
	mov esi, localhost
	mov edi, sockaddr_in
	call initIP
	; Get the Port argument
	mov esi, clientPort
	call initPort
	mov [port], eax
	call socket
	mov [sock], eax
	mov si, [port]
	call connect
	
	push	dword [sock]
	call	g_io_channel_unix_new
	add esp, 4*1
	
	push	NULL
	push	recv
	push	1;G_IO_IN
	push	eax
	call g_io_add_watch
	add esp, 4 * 4
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
	push dword [buffer]
	; push the client's socket fd
	push dword [sock]
	; Move the pointer to recv() args into ECX and make the API call
	mov ecx, esp
	add esp, 4 * 4
	mov eax, SYS_socketcall
	mov ebx, SYS_RECV
	int 0x80
	
	push dword [buffer]
	push dword [oChatView]
	call AddTextToBuffer
	add esp, 4 * 2
	mov eax, 1
	ret

event_clicked:
	push dword [oEntry]
	call gtk_entry_get_text_length
	add esp, 4 * 1
	mov ecx, eax
	push dword [oEntry]
	call gtk_entry_get_text
	add esp, 4 * 1
	mov edx, [sock]
	call send

	push	dword [oEntry]
	push 	dword [oChatView]
	call gtk_text_view_append
	add esp, 4 * 2
	
	push szEmptyString
	push dword [oEntry]
	call gtk_entry_set_text
	add esp, 4 * 2
	
	ret

event_delete:
    call    gtk_main_quit
    mov eax, 0
    ret     
    
;~ void event_destroy( GtkWidget *widget,
                    ;~ gpointer   data )
event_destroy:    
    call    gtk_main_quit
    ret
