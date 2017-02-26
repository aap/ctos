#include "k.h"

#define GPIO_C_SET 0xB0010244
#define GPIO_C_CLEAR 0xB0010248
#define GPIO_F_SET 0xB0010544
#define GPIO_F_CLEAR 0xB0010548

#define GPIO_F_LED_PIN (1 << 15)

Sys sys;
Cpu cpu;

#define SYS ((Sys*)((uint)&sys | KSEG1))

void
delay_cache(int n)
{
	int i;
	for(i = 0; i < n; i++)
		;
}
void (*delay)(int n) = (void(*)(int))((byte*)delay_cache + 0x20000000);

void
printconfig(void)
{
	uint r;
	r = cpu.status;
	printf(" status.cu3-0: %x\n", r>>28 & 0xF);
	printf(" status.rp: %x\n", r>>27 & 0x1);
	printf(" status.re: %x\n", r>>25 & 0x1);
	printf(" status.bev: %x\n", r>>22 & 0x1);
	printf(" status.ts: %x\n", r>>21 & 0x1);
	printf(" status.sr: %x\n", r>>20 & 0x1);
	printf(" status.nmi: %x\n", r>>19 & 0x1);
	printf(" status.im: %x\n", r>>8 & 0xFF);
	printf(" status.um: %x\n", r>>4 & 0x1);
	printf(" status.erl: %x\n", r>>2 & 0x1);
	printf(" status.exl: %x\n", r>>1 & 0x1);
	printf(" status.ie: %x\n", r & 0x1);

	r = cpu.cause;
	printf(" cause.bd: %x\n", r>>31 & 0x1);
	printf(" cause.ce: %x\n", r>>28 & 0x3);
	printf(" cause.iv: %x\n", r>>23 & 0x1);
	printf(" cause.wp: %x\n", r>>22 & 0x1);
	printf(" cause.ip[7:2]: %x\n", r>>10 & 0x3F);
	printf(" cause.ip[1:0]: %x\n", r>>8 & 0x3);
	printf(" cause.exc_code: %x\n", r>>2 & 0x1F);

	printf("ebase: %x\n", cpu.ebase);

	r = cpu.config;
	printf(" config.m: %x\n", r>>31 & 0x1);
	printf(" config.mdu: %x\n", r>>20 & 0x1);
	printf(" config.mm: %x\n", r>>17 & 0x3);
	printf(" config.bm: %x\n", r>>16 & 0x1);
	printf(" config.be: %x\n", r>>15 & 0x1);
	printf(" config.at: %x\n", r>>13 & 0x3);
	printf(" config.ar: %x\n", r>>10 & 0x7);
	printf(" config.mt: %x\n", r>>7 & 0x7);
	printf(" config.k0: %x\n", r & 0x7);

	r = cpu.config1;
	printf(" config1.m: %x\n", r>>31 & 0x1);
	printf(" config1.mmu_size: %x\n", r>>25 & 0x3F);
	printf(" config1.is: %x\n", r>>22 & 0x7);
	printf(" config1.il: %x\n", r>>19 & 0x7);
	printf(" config1.ia: %x\n", r>>16 & 0x7);
	printf(" config1.ds: %x\n", r>>13 & 0x7);
	printf(" config1.dl: %x\n", r>>10 & 0x7);
	printf(" config1.da: %x\n", r>>7 & 0x7);
	printf(" config1.pc: %x\n", r>>4 & 0x1);
	printf(" config1.wr: %x\n", r>>3 & 0x1);
	printf(" config1.ca: %x\n", r>>2 & 0x1);
	printf(" config1.ep: %x\n", r>>1 & 0x1);
	printf(" config1.fp: %x\n", r & 0x1);

	r = cpu.config2;
	printf(" config2.m: %x\n", r>>31 & 0x1);
	printf(" config2.tu: %x\n", r>>28 & 0x7);
	printf(" config2.ts: %x\n", r>>24 & 0xF);
	printf(" config2.tl: %x\n", r>>20 & 0xF);
	printf(" config2.ta: %x\n", r>>16 & 0xF);
	printf(" config2.su: %x\n", r>>12 & 0xF);
	printf(" config2.ss: %x\n", r>>8 & 0xF);
	printf(" config2.sl: %x\n", r>>4 & 0xF);
	printf(" config2.sa: %x\n", r & 0xF);

	r = cpu.config3;
	printf(" config3.m: %x\n", r>>31 & 0x1);
	printf(" config3.veic: %x\n", r>>6 & 0x1);
	printf(" config3.vint: %x\n", r>>5 & 0x1);
	printf(" config3.sp: %x\n", r>>4 & 0x1);
	printf(" config3.sm: %x\n", r>>1 & 0x1);
	printf(" config3.tl: %x\n", r & 0x1);

	r = cpu.config7;
	printf(" config7.alloc: %x\n", r>>2 & 0x1);
	printf(" config7.btbv: %x\n", r>>1 & 0x1);
	printf(" config7.btbe: %x\n", r & 0x1);

	printf(" index: %x\n", cpu.index);
}

void
printsomeregs(void)
{
	getc0regs(&cpu);
	printf("um:%x erl:%x exl:%x ie:%x cause:%x epc:%x\n",
		!!(cpu.status & 0x10),
		!!(cpu.status & 0x4),
		!!(cpu.status & 0x2),
		!!(cpu.status & 0x1),
		cpu.cause, cpu.epc);
}

void
ledloop(void)
{
	for(;;){
		PUT32(GPIO_F_CLEAR, GPIO_F_LED_PIN);
		delay(1000000);
		PUT32(GPIO_F_SET, GPIO_F_LED_PIN);
		delay(1000000);
	}
}

void
ledloopC(void)
{
	for(;;){
		PUT32(GPIO_F_CLEAR, GPIO_F_LED_PIN);
		delay_cache(1000000);
		PUT32(GPIO_F_SET, GPIO_F_LED_PIN);
		delay_cache(1000000);
	}
}

void
tlbExcept(void)
{
	printf("TLB exception\n");
	ledloop();
}

void
cacheExcept(void)
{
	printf("cache exception\n");
	ledloop();
}

void
generalExcept(void)
{
	int exccode;
	printf("> general exception\n> ");
	printsomeregs();
	exccode = cpu.cause>>2 & 0x1F;
	printf(">  %x %d\n", exccode, cpu.status>>21 & 1);
	switch(exccode){
	case 8:
		break;
	default:
		printf("> %x %x\n", cpu.entryhi, cpu.index);
		ledloop();
	}
}

uint startprocB(void);
uint getpc(void);

int num = 0;
#define num_C (*(int*)((uint)&num | KSEG1))

void
main(void)
{
	uint *p;

	delay(10000);
	inituart();

	printf("highmark: %x numpages: %x\n", SYS->highmark, SYS->numpages);

	printf("hello from proc %d\n", mach->number);
	printf("cache: %x tlb: %x sp: %p\n", mach->cachepolicy, mach->tlbsize, mach->sp);
	printf("pc: %p\n", getpc());

//	printf("DMMAP: %x %x\n", GET32(0xb3010024), GET32(0xb3010028));
//	for(p = (uint*)0x80010000; p < (uint*)0x80010010; p++)
//		printf("%p: %p\n", p, *p);

//	getc0regs(&cpu);
//	printconfig();
//	printsomeregs();

	dosyscall();

	startprocB();
//	getc0regs(&cpu);
//	printf("%p %p %p\n", cpu.corectrl, cpu.corestatus, cpu.reim);
//	p = (uint*)(cpu.reim & 0xFFFF0000);
//	printf(" -> %p: %p\n", p, *p);
	for(;;){
		delay(10000);
		printf("%d\n", num);
	}
	ledloop();
}

void
mainB(void)
{
	printf("hello from proc %d\n", mach->number);
	printf("cache: %x tlb: %x sp: %p\n", mach->cachepolicy, mach->tlbsize, mach->sp);
	printf("pc: %p\n", getpc());
	for(;;)
		num++;
	ledloopC();
	ledloop();
}
