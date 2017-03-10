typedef unsigned char byte;
typedef unsigned char uchar;
typedef unsigned short ushort;
typedef unsigned int uint;
typedef unsigned long ulong;
typedef unsigned long uintptr;

typedef struct C0 C0;
typedef struct Sys Sys;
typedef struct Context Context;
typedef struct Cpu Cpu;

typedef struct C0Cause C0Cause;
struct C0Cause
{
	uint	: 2,
		exccode : 5,
		: 1,
		ip : 8,
		: 6,
		wp : 1,
		iv : 1,
		: 4,
		ce : 2,
		: 1,
		bd : 1;
};

typedef struct C0Status C0Status;
struct C0Status
{
	uint	ie : 1,
		exl : 1,
		erl : 1,
		ksu : 2,
		ux : 1,
		sx : 1,
		kx : 1,
		im : 8,
		: 3,
		nmi : 1,
		sr : 1,
		ts : 1,
		bev : 1,
		px : 1,
		mx : 1,
		re : 1,
		fr : 1,
		rp : 1,
		cu : 4;
};

// temporary, for debugging
struct C0
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
	uint gp;
	uint sp;
	uint fp;
	uint ra;
	uint lo, hi;

	uint epc;
	uint cause;
	uint status;
};

#define NUMCPU 2

// Per processor state
struct Cpu
{
	int number;
	int cachePolicy;
	int TLBsize;
	uint *kernelStack;
	uint *interruptStack;
};
#define cpu ((Cpu*)CPUADDR)
Cpu *cpus[NUMCPU];
