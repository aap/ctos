#include "k.h"

#define GPIO_C_SET 0xB0010244
#define GPIO_C_CLEAR 0xB0010248
#define GPIO_F_SET 0xB0010544
#define GPIO_F_CLEAR 0xB0010548

#define GPIO_F_LED_PIN (1 << 15)

Sys sys;
C0 c0;

#define SYS ((Sys*)((uint)&sys | KSEG1))

void
delay_cache(int n)
{
	int i;
	for(i = 0; i < n; i++)
		;
}
void (*delay)(int n) = (void(*)(int))((uintptr)delay_cache + 0x20000000);

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

enum ExcCodes
{
	ExcInt,
	ExcMod,
	ExcTLBL,
	ExcTLBS,
	ExcAdEL,
	ExcAdES,
	ExcIBE,
	ExcDBE,
	ExcSys,
	ExcBp,
	ExcRI,
	ExcCpU,
	ExcOv,
	ExcTr,
	ExcMSAFPE,
	ExcFPE,
	Exc10,
	Exc11,
	ExcC2E,
	ExcTLBRI,
	ExcTLBXI,
	ExcMSADis,
	ExcMDMX,
	ExcWatch,
	ExcMCheck,
	ExcThread,
	ExcDSPDis,
	ExcGE,
	Exc1c,
	Exc1d,
	ExcCacheErr,
	Exc1f,
};

static char *excnames[] = {
	"Int",
	"Mod",
	"TLBL",
	"TLBS",
	"AdEL",
	"AdES",
	"IBE",
	"DBE",
	"Sys",
	"Bp",
	"RI",
	"CpU",
	"Ov",
	"Tr",
	"MSAFPE",
	"FPE",
	"-- 0x10",
	"-- 0x11",
	"C2E",
	"TLBRI",
	"TLBXI",
	"MSADis",
	"MDMX",
	"WATCH",
	"MCheck",
	"Thread",
	"DSPDis",
	"GE",
	"-- 0x1c",
	"-- 0x1d",
	"CacheErr",
	"-- 0x1f",
};

void
interrupt(Context *ctx)
{
	printf("interrupt\n");
	printf(" %p %p %p\n", ctx->status, ctx->cause, ctx->epc);
	timerint();
}

void
generalExcept(Context *ctx)
{
	int exccode;
	exccode = ctx->cause>>2 & 0x1F;
	printf("> general exception %s\n> ", excnames[exccode]);
	printf("um:%x erl:%x exl:%x ie:%x cause:%x epc:%x\n",
		!!(ctx->status & 0x10),
		!!(ctx->status & 0x4),
		!!(ctx->status & 0x2),
		!!(ctx->status & 0x1),
		ctx->cause, ctx->epc);
	printf(">  %d\n", ctx->status>>21 & 1);

	switch(exccode){
	case ExcInt:
		interrupt(ctx);
		break;
	case ExcSys:
		printf(" SYSTEM CALL!\n");
		ctx->epc += 4;
		break;
	default:
		printf("> %x %x\n", c0.entryhi, c0.index);
		ledloop();
	}
}

int num = 0;
#define num_C (*(int*)((uint)&num | KSEG1))

void
main(void)
{
	delay(10000);
	inituart();

	printf("highmark: %x numpages: %x\n", SYS->highmark, SYS->numpages);

	printf("hello from proc %d\n", cpu->number);
	printf("cache: %x tlb: %x kernelStack: %p\n", cpu->cachePolicy, cpu->TLBsize, cpu->kernelStack);
	getc0regs(&c0);
	printf("%p %p\n", c0.ebase, c0.intctl);

	printconfig();
	printsomeregs();


	enableint();

	timer();

	dosyscall();

//	startprocB();

	for(;0;){
		delay(100000);
		printf("%d\n", num);
	}
	ledloop();
}

void
mainB(void)
{
	printf("hello from proc %d\n", cpu->number);
	printf("cache: %x tlb: %x kernelStack: %p\n", cpu->cachePolicy, cpu->TLBsize, cpu->kernelStack);
	getc0regs(&c0);
	printf("%p %p\n", c0.ebase, c0.intctl);
	for(;;)
		num++;
	ledloopC();
	ledloop();
}
