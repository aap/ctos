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

	// get processor number
	mfc0	s6,c0_ebase
	andi	s6,s6,0x3FF

	// get cache policy
	mfc0	s0,c0_config
	andi	s0,s0,0x7	// kseg0 cache policy
	sll	s1,s0,3

	// init some regs
	mtc0	zero,c0_status
	mtc0	zero,c0_ebase		// exception base 0x80000000
	mtc0	zero,c0_intctl		// all interrupts at same vector
	mtc0	zero,c0_pagemask	// 4k pages
	mfc0	t0,c0_cause
	and	t0,t0,~0x00800000	// disable special interrupt vector
	mtc0	t0,c0_cause
	li	t1,1
	mtc0	t1,c0_wired

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
	sw	s6,CPUADDR + CpuNumber
	sw	s0,CPUADDR + CpuCachePolicy
	sw	t1,CPUADDR + CpuTLBsize

	// Get 16k for the kernel stack
	jal	allocpagesK0
	li	a0,4
	addiu	sp,v0,4*PAGE_SIZE
	sw	sp,CPUADDR + CpuKernelStack

//	// Get 8k for the interrupt stack
//	jal	allocpagesK0
//	li	a0,2
//	addiu	sp,v0,2*PAGE_SIZE
//	sw	sp,CPUADDR + CpuInterruptStack

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
	and	t0,t0,~2	// take out of reset
	ori	t0,t0,0x200	// use dedicated entry
	mtc0	t0,c0_corectrl

	jr	ra
	nop
.end startprocB

TEXT(enableint, 0)
	.set noreorder
	mfc0	t0,c0_status
	ori	t0,t0,0x0401	// enable interrupt 0
	mtc0	t0,c0_status
	jr	ra
	ehb
	.set reorder
.end enableint

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

// should save: epc, status, cause, badvaddr

/*
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
*/

TrapGeneral:
	mfc0	k0,c0_status
	andi	k0,0x10		// user mode flag
	beq	k0,zero,1f	// eq if kernel
	 move	k1,sp
	// user - get fresh kernel stack
	lw	sp,CPUADDR + CpuKernelStack
1:
	addiu	sp,sp,CtxSize

	sw	AT,CtxAt(sp)
	sw	v0,CtxV0(sp)
	sw	v1,CtxV1(sp)
	sw	a0,CtxA0(sp)
	sw	a1,CtxA1(sp)
	sw	a2,CtxA2(sp)
	sw	a3,CtxA3(sp)
	sw	t0,CtxT0(sp)
	sw	t1,CtxT1(sp)
	sw	t2,CtxT2(sp)
	sw	t3,CtxT3(sp)
	sw	t4,CtxT4(sp)
	sw	t5,CtxT5(sp)
	sw	t6,CtxT6(sp)
	sw	t7,CtxT7(sp)
	sw	s0,CtxS0(sp)
	sw	s1,CtxS1(sp)
	sw	s2,CtxS2(sp)
	sw	s3,CtxS3(sp)
	sw	s4,CtxS4(sp)
	sw	s5,CtxS5(sp)
	sw	s6,CtxS6(sp)
	sw	s7,CtxS7(sp)
	sw	t8,CtxT8(sp)
	sw	t9,CtxT9(sp)
	sw	gp,CtxGp(sp)
	sw	k1,CtxSp(sp)
	sw	fp,CtxFp(sp)
	sw	ra,CtxRa(sp)
	mflo	t0
	mfhi	t1
	sw	t0,CtxLo(sp)
	sw	t1,CtxHi(sp)
	mfc0	t2,c0_epc
	sw	t2,CtxEpc(sp)
	mfc0	t3,c0_cause
	sw	t3,CtxCause(sp)
	mfc0	t4,c0_status
	sw	t4,CtxStatus(sp)

	la	t0,generalExcept
	jalr	t0
	move	a0,sp

	lw	t2,CtxEpc(sp)
	mtc0	t2,c0_epc
	lw	t1,CtxHi(sp)
	lw	t0,CtxLo(sp)
	mthi	t1
	mtlo	t0
	lw	AT,CtxAt(sp)
	lw	v0,CtxV0(sp)
	lw	v1,CtxV1(sp)
	lw	a0,CtxA0(sp)
	lw	a1,CtxA1(sp)
	lw	a2,CtxA2(sp)
	lw	a3,CtxA3(sp)
	lw	t0,CtxT0(sp)
	lw	t1,CtxT1(sp)
	lw	t2,CtxT2(sp)
	lw	t3,CtxT3(sp)
	lw	t4,CtxT4(sp)
	lw	t5,CtxT5(sp)
	lw	t6,CtxT6(sp)
	lw	t7,CtxT7(sp)
	lw	s0,CtxS0(sp)
	lw	s1,CtxS1(sp)
	lw	s2,CtxS2(sp)
	lw	s3,CtxS3(sp)
	lw	s4,CtxS4(sp)
	lw	s5,CtxS5(sp)
	lw	s6,CtxS6(sp)
	lw	s7,CtxS7(sp)
	lw	t8,CtxT8(sp)
	lw	t9,CtxT9(sp)
	lw	gp,CtxGp(sp)
	lw	fp,CtxFp(sp)
	lw	ra,CtxRa(sp)

	lw	sp,CtxSp(sp)
	eret

TrapGeneral_end:
.set reorder
.set at

/*
Interrupt:
	.set noreorder
	.set noat

	lw	k0,CPUADDR + CpuInterruptStack
	addiu	k0,k0,CtxSize
	sw	AT,CtxAt(k0)
	sw	v0,CtxV0(k0)
	sw	v1,CtxV1(k0)
	sw	a0,CtxA0(k0)
	sw	a1,CtxA1(k0)
	sw	a2,CtxA2(k0)
	sw	a3,CtxA3(k0)
	sw	t0,CtxT0(k0)
	sw	t1,CtxT1(k0)
	sw	t2,CtxT2(k0)
	sw	t3,CtxT3(k0)
	sw	t4,CtxT4(k0)
	sw	t5,CtxT5(k0)
	sw	t6,CtxT6(k0)
	sw	t7,CtxT7(k0)
	sw	s0,CtxS0(k0)	// s0-7 really needed?
	sw	s1,CtxS1(k0)
	sw	s2,CtxS2(k0)
	sw	s3,CtxS3(k0)
	sw	s4,CtxS4(k0)
	sw	s5,CtxS5(k0)
	sw	s6,CtxS6(k0)
	sw	s7,CtxS7(k0)
	sw	t8,CtxT8(k0)
	sw	t9,CtxT9(k0)
	// k0...
	sw	k1,CtxK1(k0)
	sw	gp,CtxGp(k0)
	sw	sp,CtxSp(k0)
	sw	fp,CtxFp(k0)
	sw	ra,CtxRa(k0)
	mflo	t0
	mfhi	t1
	sw	t0,CtxLo(k0)
	sw	t1,CtxHi(k0)
	mfc0	t2,c0_epc
	sw	t2,CtxEpc(k0)
	mfc0	t3,c0_cause
	sw	t3,CtxCause(k0)
	mfc0	t4,c0_status
	sw	t4,CtxStatus(k0)

	move	sp,k0

	la	t0,interrupt
	jalr	t0
	move	a0,sp

	move	k0,sp
	lw	t2,CtxEpc(k0)
	mtc0	t2,c0_epc
	lw	t1,CtxHi(k0)
	lw	t0,CtxLo(k0)
	mthi	t1
	mtlo	t0
	lw	ra,CtxRa(k0)
	lw	fp,CtxFp(k0)
	lw	sp,CtxSp(k0)
	lw	gp,CtxGp(k0)
	lw	k1,CtxK1(k0)
	lw	t9,CtxT9(k0)
	lw	t8,CtxT8(k0)
	lw	s7,CtxS7(k0)
	lw	s6,CtxS6(k0)
	lw	s5,CtxS5(k0)
	lw	s4,CtxS4(k0)
	lw	s3,CtxS3(k0)
	lw	s2,CtxS2(k0)
	lw	s1,CtxS1(k0)
	lw	s0,CtxS0(k0)
	lw	t7,CtxT7(k0)
	lw	t6,CtxT6(k0)
	lw	t5,CtxT5(k0)
	lw	t4,CtxT4(k0)
	lw	t3,CtxT3(k0)
	lw	t2,CtxT2(k0)
	lw	t1,CtxT1(k0)
	lw	t0,CtxT0(k0)
	lw	a3,CtxA3(k0)
	lw	a2,CtxA2(k0)
	lw	a1,CtxA1(k0)
	lw	a0,CtxA0(k0)
	lw	v1,CtxV1(k0)
	lw	v0,CtxV0(k0)
	lw	AT,CtxAt(k0)
	eret

	.set reorder
	.set at
Interrupt_end:
*/

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
