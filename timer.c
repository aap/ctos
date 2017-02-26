#include "k.h"
#include "jz4780.h"

enum
{
	Mhz	= 1000000,
};

void
timer(void)
{
	// We'll use the EXTAL source, which ticks at 48Mhz
	PUT16(OstCsr, 2<<3);	// CLK/16 -> 3Mhz
	PUT32(OstCntL, 0);
	PUT32(OstCntH, 0);
	PUT32(OstDr, 3*Mhz);	// interrupt every second
	PUT16(OstCsr, GET16(OstCsr) | 4);	// use EXTAL clock
	PUT16(Tesr, 0x8000);	// enable OST counter
	PUT32(Tmcr, 0x8000);	// clear OST interrupt mask
	PUT32(Icmcr0, 0x08000000);
}

void
timerint(void)
{
	printf("tick\n");
	PUT32(Tfcr, 0x8000);
}
