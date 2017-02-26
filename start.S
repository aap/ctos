#include "mipsasm.h"

#define ICACHE 0
#define DCACHE 1
#define L2CACHE 3
#define L3CACHE 2

#define INDEX_STORE_TAG_I	(0x8 | ICACHE)
#define INDEX_STORE_TAG_D	(0x8 | DCACHE)
#define INDEX_INVALIDATE_I	(0x0 | ICACHE)
#define INDEX_INVALIDATE_D	(0x0 | DCACHE)

#define LINE_SIZE 32
#define DCACHE_SIZE 8*128*LINE_SIZE
#define ICACHE_SIZE 8*128*LINE_SIZE

#define PROC_COUNT _start-KSEG0+KSEG1-4

// loaded at virtual 0x8800_0000 via u-boot
// physical dram at 0x2000_0000-0x6000_0000
//  mirrored at 0x0000_0000 - 0x1000_0000

#define DRAM_PHYS  0x20000000

// once-only entry for boot processor:
//  relocate to real address
//  init some kernel data
//  clear bss
//  jump to startup
TEXT(_start, 0)
	.set noreorder
	// relocate
	li	t0,0x88000000	// source
	la	t1,_start	// destination
	la	t2,_bss_start	// dest end
1:	 lw	t3,(t0)
	 sw	t3,(t1)
	 addiu	t0,4
	 bne	t1,t2,1b
	 addiu	t1,4

	// set processor counter to zero
	sw	zero,PROC_COUNT

	// clear bss
	la	t0,_bss_start
	la	t1,_bss_end
1:	 sw	zero,(t0)
	 bne	t0,t1,1b
	 addiu	t0,4

	// flush Dcache
	li	t0,KSEG0
	addu	t1,t0,DCACHE_SIZE-LINE_SIZE
1:	 cache	INDEX_INVALIDATE_D,(t0)
	 bne	t0,t1,1b
	 addiu	t0,LINE_SIZE

	// flush Icache
	li	t0,KSEG0
	addu	t1,t0,ICACHE_SIZE-LINE_SIZE
1:	 cache	INDEX_INVALIDATE_I,(t0)
	 bne	t0,t1,1b
	 addiu	t0,LINE_SIZE

	la	s7,sys-KSEG0+KSEG1

	// calculate end of kernel in pages
	la	t0,_bss_end-KSEG0
	addiu	t0,t0,PAGE_SIZE-1
	srl	t0,t0,PAGE_SHIFT
	sw	t0,SysHighmark(s7)
	// number of pages (1GB)
	li	t1,0x40000000>>PAGE_SHIFT
	sw	t1,SysNumpages(s7)

	// jump to startup at new location
	la	t0,startup
	jr	t0
	nop
	.set reorder
.end _start

// Entry for new processor executing in KSEG1
// Has to be 64k aligned and is copied to _start by boot processor
entry:
	li	t0,KSEG1
	la	t1,initproc
	or	t0,t0,t1
	jr	t0
entry_end:

// Init new processor (KSEG1)
//  init caches and jump to startup (KSEG0)
TEXT(initproc, 0)
	.set noreorder
	// for some reason KSEG0 is set to uncached on reset, enable it
	mfc0	t1,c0_config
	ori	t1,t1,3
	mtc0	t1,c0_config

	mtc0	zero,c0_taglo

	// initialize Icache
	li	t0,KSEG0
	li	t1,ICACHE_SIZE
	addu	t1,t0,t1
	addiu	t1,-LINE_SIZE
1:	cache	INDEX_STORE_TAG_I,(t0)
	bne	t0,t1,1b
	addiu	t0,LINE_SIZE

	// initialize Dcache
	li	t0,KSEG0
	li	t1,DCACHE_SIZE
	addu	t1,t0,t1
	addiu	t1,-LINE_SIZE
1:	cache	INDEX_STORE_TAG_D,(t0)
	bne	t0,t1,1b
	addiu	t0,LINE_SIZE

	la	t0,startup
	jr	t0
	nop
	.set reorder
.end initproc

TEXT(startup, 0)
	.set noreorder

	la	gp,_gp
	la	s7,sys-KSEG0+KSEG1

	// get processor number (s6 = PROC_COUNT++)
	la	t0,PROC_COUNT
	lw	s6,(t0)
	addiu	t1,s6,1
	sw	t1,(t0)

	// init some regs
	mtc0	zero,c0_status
	mtc0	zero,c0_pagemask
	li	t1,1
	mtc0	t1,c0_wired

	// get processor information
	mfc0	s0,c0_config
	andi	s0,s0,0x7	// kseg0 cache policy
	sll	s1,s0,3

	// Get 16k for the kernel stack
	jal	allocpagesK0
	li	a0,4
	addiu	sp,v0,4*PAGE_SIZE

	// copy exception handlers and processor entry if boot processor
	bnez	s6,2f
	// TLB miss
	.set reorder
	li	a0,KSEG0
	la	a1,TrapTLB
	la	a2,TrapTLB_end
	jal	copy
	// cache
	li	a0,KSEG0+0x100
	la	a1,TrapCache
	la	a2,TrapCache_end
	jal	copy
	// general
	li	a0,KSEG0+0x180
	la	a1,TrapGeneral
	la	a2,TrapGeneral_end
	jal	copy
	.set noreorder

	// install entry for other processors
	la	t0,_start	// destination
	la	t1,entry	// source
	la	t2,entry_end	// source end
1:	 lw	t3,(t1)
	 sw	t3,(t0)
	 addiu	t0,4
	 bne	t1,t2,1b
	 addiu	t1,4

	jal	flushcaches
	nop

2:
	// find out TLB size
	mfc0	t1,c0_config1
	srl	t1,t1,25
	andi	t1,t1,0x3f	// last index
	addiu	t1,t1,1

	// clear TLB
	li	t2,KSEG0
	move	t0,zero	
	mtc0	zero,c0_entrylo0
	mtc0	zero,c0_entrylo1
	mtc0	t0,c0_index
	mtc0	t2,c0_entryhi
1:	 addiu	t0,t0,1
	 addiu	t2,t2,1<<13
	 tlbwi
	 mtc0	t2,c0_entryhi
	 bne	t0,t1,1b
	 mtc0	t0,c0_index

	//
	// allocate two pages and wire them to 0xFFFF_E000
	//
	jal	allocpages
	li	a0,2
	move	s4,v0
	li	t2,0xFFFFE000
	mtc0	zero,c0_index
	mtc0	t2,c0_entryhi
	sll	t3,s4,6		// page frame number
	or	t3,t3,s1	// cache policy
	ori	t3,t3,0x7	// D, V, G
	mtc0	t3,c0_entrylo0
	addiu	t3,1<<6		// next page
	mtc0	t3,c0_entrylo1
	ehb
	tlbwi

	// save processor config
	sw	s6,0xffffe000	// processor number
	sw	s0,0xffffe004	// cache policy
	sw	t1,0xffffe008	// TLB size
	sw	sp,0xffffe00C

	bnez	s6,2f
	nop
	la	t0,main
	jr	t0
	nop

2:	la	t0,mainB
	jr	t0
	nop

	.set reorder
.end startup


TEXT(startprocB, 0)
	// set entry point in KSEG1
	// NB: entry has been copied to _start
	li	t1,KSEG1
	la	t0,_start
	or	t0,t0,t1
	ori	t0,t0,0x0303	// mask everything for now
	mtc0	t0,c0_reim

	la	t1,0x10000000|KSEG1
	// ungate P1 clock
	lw	t2,0x28(t1)
	andi	t2,t2,0x7FFF
	sw	t2,0x28(t1)

	mfc0	t0,c0_corectrl
	li	t1,~2
	and	t0,t0,t1	// take out of reset
	ori	t0,t0,0x200	// use dedicated entry
	mtc0	t0,c0_corectrl

	jr	ra
	nop
.end startprocB

.set noreorder
.set noat
TrapTLB:
	la	t0,tlbExcept
	jalr	t0
	nop
TrapTLB_end:

TrapCache:
	// this should run in KSEG1 of course
	la	t0,cacheExcept
	jalr	t0
	nop
TrapCache_end:

TrapGeneral:
	move	k0,ra
	la	t0,generalExcept
	jalr	t0
	nop
	mfc0	t0,c0_epc
	addiu	t0,4
	mtc0	t0,c0_epc
	move	ra,k0
	nop
	eret
TrapGeneral_end:
.set reorder
.set at

TEXT(flushcaches, 0)
	.set noreorder
	// flush Dcache
	li	t0,KSEG0
	addu	t1,t0,DCACHE_SIZE-LINE_SIZE
1:	 cache	INDEX_INVALIDATE_D,(t0)
	 bne	t0,t1,1b
	 addiu	t0,LINE_SIZE

	// flush Icache
	li	t0,KSEG0
	addu	t1,t0,ICACHE_SIZE-LINE_SIZE
1:	 cache	INDEX_INVALIDATE_I,(t0)
	 bne	t0,t1,1b
	 addiu	t0,LINE_SIZE
	jr	ra
	nop
	.set reorder
.end flushcaches

// copy words
// a0 - dest, a1 - start, a2 - end
TEXT(copy, 0)
1:	 lw	t0,(a1)
	 addiu	a1,4
	 sw	t0,(a0)
	 addiu	a0,4
	 bne	a1,a2,1b
	jr	ra
.end copy

// Allocate a0 pages; return page address
TEXT(allocpages, 0)
	lw	v0,SysHighmark(s7)
	addu	t0,v0,a0
	sw	t0,SysHighmark(s7)
	j	ra
.end allocpages

// Allocate a0 pages; return KSEG0 address
TEXT(allocpagesK0, 0)
	move	t1,ra
	jal	allocpages
	sll	v0,v0,PAGE_SHIFT
	addu	v0,v0,KSEG0
	jr	t1
.end allocpagesK0

TEXT(getc0regs, 0)
	.set noat
	.set noreorder
	mfc0	t0,c0_status
	sw	t0,0(a0)
	mfc0	t0,c0_cause
	sw	t0,4(a0)
	mfc0	t0,c0_epc
	sw	t0,8(a0)
	mfc0	t0,c0_ebase
	sw	t0,0xC(a0)
	mfc0	t0,c0_config
	sw	t0,0x10(a0)
	mfc0	t0,c0_config1
	sw	t0,0x14(a0)
	mfc0	t0,c0_config2
	sw	t0,0x18(a0)
	mfc0	t0,c0_config3
	sw	t0,0x1C(a0)
	mfc0	t0,c0_config7
	sw	t0,0x20(a0)
	mfc0	t0,c0_entryhi
	sw	t0,0x24(a0)
	mfc0	t0,c0_entrylo0
	sw	t0,0x28(a0)
	mfc0	t0,c0_entrylo1
	sw	t0,0x2C(a0)
	mfc0	t0,c0_index
	sw	t0,0x30(a0)
	mfc0	t0,c0_corectrl
	sw	t0,0x34(a0)
	mfc0	t0,c0_corestatus
	sw	t0,0x38(a0)
	mfc0	t0,c0_reim
	sw	t0,0x3C(a0)

	jr	ra
	nop
	.set at
	.set reorder
.end getc0regs

TEXT(getpc, 0)
	move	v0,ra
	jr	ra
.end getpc

TEXT(dosyscall, 0)
	syscall
	jr	ra
.end dosyscall
