typedef unsigned char byte;
typedef unsigned char uchar;
typedef unsigned short ushort;
typedef unsigned int uint;
typedef unsigned long ulong;
typedef unsigned long uintptr;

typedef struct Cpu Cpu;
typedef struct Sys Sys;
typedef struct Context Context;
typedef struct Mach Mach;

// temporary
struct Cpu
{
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
	int intctl;
};

// Global system state
struct Sys
{
	int highmark;
	int numpages;
};
extern Sys sys;

struct Context
{
	uint at;
	uint v0, v1;
	uint a0, a1, a2, a3;
	uint t0, t1, t2, t3, t4, t5, t6, t7;
	uint s0, s1, s2, s3, s4, s5, s6, s7;
	uint t8, t9;
	uint k0, k1;
	uint gp;
	uint sp;
	uint fp;
	uint ra;
	uint lo, hi;

	uint epc;
	uint cause;
	uint status;
};

#define NUMMACH 2

// Per processor state
struct Mach
{
	int number;
	int cachePolicy;
	int TLBsize;
	uint *kernelStack;
	uint *interruptStack;
};
#define mach ((Mach*)MACHADDR)
Mach *machs[NUMMACH];
