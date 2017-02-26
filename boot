
setenv serverip 172.16.0.1
setenv ipaddr 172.16.0.2
tftpboot 172.16.0.1:ci20.bin

setenv serverip 10.24.0.11
setenv ipaddr 10.24.4.2
tftpboot 10.24.0.11:ci20.bin

go 0x88000000
go 0xA8000000
