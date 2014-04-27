global main

%assign NULL 0

;GTK
extern  gtk_init, gtk_builder_new, gtk_builder_add_from_file, gtk_builder_get_object
extern gtk_builder_connect_signals, g_object_unref, gtk_widget_show_all, gtk_main
extern gtk_main_quit, g_signal_connect_data, gtk_text_view_set_buffer, gtk_text_buffer_set_text

; Appedn to textview
extern gtk_text_view_get_buffer, gtk_text_buffer_get_end_iter, gtk_text_buffer_insert, gtk_entry_get_text, gtk_text_buffer_new, gtk_text_view_set_buffer

section .data
	; GUI IDs
    szGladeFile db 'chat.glade', 0
    szIDMainWin db 'mWin', 0
    szIDMainGrid db 'mGrid', 0
    szIDchatView db 'chatView', 0
    szIDSubGrid db 'sGrid', 0
    szIDEntry db 'entry', 0
    szIDSendBtn db 'send', 0
    
    ; Events
    szevent_delete      db  "delete-event", 0
	szevent_destroy     db  "destroy", 0
	szevent_clicked     db  "clicked", 0


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
    
        ; Signals
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

    call    gtk_main
    ret

event_clicked:
	push NULL
	call gtk_text_buffer_new
	add esp, 4 * 1
	mov [oTextBuffer], eax
	
	push	dword [oEntry]
	call	gtk_entry_get_text
	add		esp, 4 * 1
	mov		[oText], eax
	
	push -1
	push dword [oText]
	push dword [oTextBuffer]
	call gtk_text_buffer_set_text
	add esp, 4 * 3
	
	
	push	dword [oTextBuffer]
	push	dword [oChatView]
	call	gtk_text_view_set_buffer
	add		esp, 4 * 2
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
