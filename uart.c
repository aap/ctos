#include "k.h"

enum
{
	URbr	= 0x00,
	UThr	= 0x00,
	UDllr	= 0x00,
	UDlhr	= 0x04,
	UIer	= 0x04,
	UIir	= 0x08,
	UFcr	= 0x08,
	ULcr	= 0x0C,
	UMcr	= 0x10,
	ULsr	= 0x14,
	UMsr	= 0x18,
	USpr	= 0x1C,
};

#define UART(n, a) (0xB0030000 + (n)*0x1000 + (a))

void
inituart(void)
{
	PUT8(UART(0, UFcr), 0);
	PUT8(UART(0, ULcr), 0x80);	/* set DLAB */
	PUT8(UART(0, UDllr), 26);
	PUT8(UART(0, UDlhr), 0);	/* baud rate = 115200 hopefully */
	PUT8(UART(0, ULcr), 0x03);	/* 8N1 */
	PUT8(UART(0, UFcr), 0xC7);	/* 60 bit level FIFO */
	PUT8(UART(0, UIer), 0x00);	/* no interrupts */
	PUT8(UART(0, UFcr), 0xD7);	/* enable UART */
}

void
uartout(int c)
{
	while((GET8(UART(0, ULsr)) & 0x20) == 0)
		;
	PUT8(UART(0, UThr), c);
	if(c == '\n')
		PUT8(UART(0, UThr), '\r');
}

int
uartin(void)
{
	int c;
	while((GET8(UART(0, ULsr)) & 1) == 0)
		;
	c = GET8(UART(0, UThr));
	if(c == '\r')
		c = '\n';
	return c;
}
