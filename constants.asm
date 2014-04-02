; Socket arguments
%assign IPPROTO_TCP			6
%assign SOCK_STREAM         1
%assign AF_INET             2

; Socket subcalls
%assign SYS_socketcall      102
%assign SYS_SOCKET          1
%assign SYS_BIND			2
%assign SYS_CONNECT         3
%assign SYS_LISTEN			4
%assign SYS_ACCEPT			5
%assign SYS_SEND            9
%assign SYS_RECV            10

; Terminal I/O subcalls
%assign SYS_READ			3
%assign SYS_WRITE           4

; I/O File descriptors
%assign stdout           	1
%assign stdin				0

; Other
%assign SYS_FORK			2
