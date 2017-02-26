PREFIX=mipsel-elf
AS=$(PREFIX)-as
CC=$(PREFIX)-gcc
LD=$(PREFIX)-ld
OBJCOPY=$(PREFIX)-objcopy
#CFLAGS=-march=mips32r2 -mno-abicalls -fno-pic -ffreestanding
CFLAGS=-march=mips32r2 -mno-abicalls -ffreestanding

OBJS=start.o temp.o main.o uart.o timer.o prf.o

/srv/tftp/ci20.bin: ci20.bin
	cp ci20.bin /srv/tftp/ci20.bin

ci20.bin: ci20.elf
	$(OBJCOPY) -O binary $< $@

ci20.elf: $(OBJS) linker.ld
	$(LD) -T linker.ld -o $@ $(OBJS)

%.o: %.[Sc]
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f *.o ci20.bin ci20.elf
