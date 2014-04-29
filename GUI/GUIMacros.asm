%macro addWidget 3
	; Add a widget from .glade file using a Gtk Builder
	; %1 - Gtk Builder
	; %2 - Widget ID
	; %3 - Uninitilize Variable (resd)
	push    %2
    push    dword [%1]
    call    gtk_builder_get_object 
    add     esp, 4 * 2
    mov     [%3], eax
%endmacro

%macro addEvent 3
	; Add an event handler
	; %1 - Handler
	; %2 - Signal ID
	; %3 - Signal Source (The widget to monitor for signal)
    push    NULL
    push    NULL
    push    NULL
    push    %1
    push    %2
    push    dword [%3]
    call    g_signal_connect_data
    add     esp, 4 * 6
%endmacro
