/*
 * ROM 링커 스크립트
 *   코드와 상수는 ROM(0x0)에 두고 그 자리에서 실행한다.
 *   변수와 스택은 칩 내부 SRAM(0x0E000000)에 둔다.
 *   .data의 초깃값은 ROM에 저장해 두었다가 부팅 때 SRAM으로 복사한다.
 */
ENTRY(_start)

MEMORY
{
	ROM  (rx)  : ORIGIN = 0x00000000, LENGTH = 64K
	SRAM (rwx) : ORIGIN = 0x0E000000, LENGTH = 1M
}

SECTIONS
{
	.text : {
		KEEP(*(.text.boot))  /* _start 가 반드시 0번지에 오도록 맨 앞 */
		*(.text*)
	} > ROM

	.rodata : {
		*(.rodata*)
	} > ROM

	.data : {
		. = ALIGN(8);
		__data_start = .;
		*(.data*)
		. = ALIGN(8);
		__data_end = .;
	} > SRAM AT > ROM          /* 실행 주소(VMA)는 SRAM, 저장 주소(LMA)는 ROM */
	__data_load = LOADADDR(.data);

	.bss (NOLOAD) : {
		. = ALIGN(8);
		__bss_start = .;
		*(.bss*)
		*(COMMON)
		. = ALIGN(8);
		__bss_end = .;
	} > SRAM

	.stack (NOLOAD) : {
		. = ALIGN(16);
		. += 16K;
		__stack_top = .;
	} > SRAM

	/DISCARD/ : {
		*(.comment) *(.note*) *(.eh_frame*)
	}
}
