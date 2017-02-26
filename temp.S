#include "mipsasm.h"

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
	mfc0	t0,c0_intctl
	sw	t0,0x40(a0)

	jr	ra
	nop
	.set at
	.set reorder
.end getc0regs

TEXT(getpc, 0)
	move	v0,ra
	jr	ra
.end getpc

TEXT(getcause, 0)
	mfc0	v0,c0_cause
	jr	ra
.end getcause

TEXT(dosyscall, 0)
	syscall
	jr	ra
.end dosyscall
