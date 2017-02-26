OUTPUT_ARCH(mips)

ENTRY(_start)

SECTIONS
{
	. = 0x80010000;

	_text_start = .;
	.text : {
		*(.text)
	}
	_text_end = .;

	_rodata_start = .;
	.rodata : {
		*(.rodata)
		*(.rodata.*)
	}
	_rodata_end = .;

	_data_start = .;
	.data : {
		*(.data*)
	}
	_data_end = .;

	_gp = (ALIGN(0x10) + 0x7ff0);
	_sdata_start = .;
	.sdata : {
		*(.sdata*)
	}
	_sdata_end = .;

	_bss_start = .;
	.sbss (NOLOAD) : {
		*(.sbss*)
	}
	.bss (NOLOAD) : {
		*(.bss*)
	}
	_bss_end = .;
}
