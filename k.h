#include "mips.h"

typedef unsigned char byte;
typedef unsigned char uchar;
typedef unsigned short ushort;
typedef unsigned int uint;
typedef unsigned long ulong;

#define PUT8(a,v)   (*(byte*)(a) = v)
#define PUT32(a,v)  (*(uint*)(a) = v)
#define GET8(a)     (*(byte*)(a))
#define GET32(a)    (*(uint*)(a))

typedef struct Cpu Cpu;
struct Cpu {
	int status;
	int cause;
	int epc;
	int ebase;
	int config;
	int config1;
	int config2;
	int config3;
	int config7;
	int entryhi;
	int entrylo0;
	int entrylo1;
	int index;
	int corectrl;
	int corestatus;
	int reim;
};

// Global system state
typedef struct Sys Sys;
struct Sys
{
	int highmark;
	int numpages;
};
extern Sys sys;

#define NUMMACH 2

// Per processor state
typedef struct Mach Mach;
struct Mach
{
	int number;
	int cachepolicy;
	int tlbsize;
	uint sp;
	// kernel stack...
};
#define mach ((Mach*)MACHADDR)

void getc0regs(Cpu *cpu);
void dosyscall(void);

void putchar(int c);
int getch(void);
int getchar(void);
void puts(char *s);
void printn(int n, int b);
void printf(char *fmt, ...);

void inituart(void);
int uartin(void);
void uartout(int c);
