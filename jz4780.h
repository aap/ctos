enum
{
	// Interrupt Controller
	Intc	= 0x10001000 | KSEG1,
	Icsr0	= Intc + 0x0,
	Icmr0	= Intc + 0x4,
	Icmsr0	= Intc + 0x8,
	Icmcr0	= Intc + 0xC,
	Icpr0	= Intc + 0x10,
	Icsr1	= Intc + 0x20,
	Icmr1	= Intc + 0x24,
	Icmsr1	= Intc + 0x28,
	Icmcr1	= Intc + 0x2C,
	Icpr1	= Intc + 0x30,

	// Timer
	Timer	= 0x10002000 | KSEG1,
	Ter	= Timer + 0x10,
	Tesr	= Timer + 0x14,
	Tecr	= Timer + 0x18,
	Tfr	= Timer + 0x20,
	Tfsr	= Timer + 0x24,
	Tfcr	= Timer + 0x28,
	Tmr	= Timer + 0x30,
	Tmsr	= Timer + 0x34,
	Tmcr	= Timer + 0x38,

	// Operating System Timer
	Ost	= Timer + 0xE0,
	OstDr	= Ost + 0x0,
	OstCntL	= Ost + 0x4,
	OstCntH	= Ost + 0x8,
	OstCsr	= Ost + 0xC,
	OstHBuf	= Ost + 0x1C,
};

