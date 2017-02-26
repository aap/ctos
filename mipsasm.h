#include "mips.h"

#define zero $0
#define AT $1
#define v0 $2
#define v1 $3
#define a0 $4
#define a1 $5
#define a2 $6
#define a3 $7
#define t0 $8
#define t1 $9
#define t2 $10
#define t3 $11
#define t4 $12
#define t5 $13
#define t6 $14
#define t7 $15
#define s0 $16
#define s1 $17
#define s2 $18
#define s3 $19
#define s4 $20
#define s5 $21
#define s6 $22
#define s7 $23
#define t8 $24
#define t9 $25
#define k0 $26
#define k1 $27
#define gp $28
#define sp $29
#define fp $30
#define ra $31

#define c0_index $0
#define c0_random $1
#define c0_entrylo0 $2
#define c0_entrylo1 $3
#define c0_context $4
#define c0_pagemask $5
#define c0_wired $6
#define c0_badvaddr $8
#define c0_entryhi $10
#define c0_status $12
#define c0_intctl $12,1
#define c0_corectrl $12,2
#define c0_corestatus $12,3
#define c0_reim $12,4
#define c0_cause $13
#define c0_epc $14
#define c0_prid $15
#define c0_ebase $15,1
#define c0_config $16
#define c0_config1 $16,1
#define c0_config2 $16,2
#define c0_config3 $16,3
#define c0_config7 $16,7
#define c0_lladdr $17
#define c0_watchlo $18
#define c0_watchhi $19
#define c0_debug $23
#define c0_depc $24
#define c0_errctl $26
#define c0_taglo $28,0
#define c0_datalo $28,1
#define c0_errorepc $30
#define c0_desave $31

#define TEXT(name, fsize)       \
	.text;                  \
	.align  2;              \
	.globl  name;           \
	.ent    name;           \
name:;                          \
	.frame  sp,fsize,ra;

#define SysHighmark	0x0
#define SysNumpages	0x4
