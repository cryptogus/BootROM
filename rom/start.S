/*
 * 리셋 직후 CPU가 실행하는 첫 코드 (주소 0x0)
 * 아직 스택도, 초기화된 변수도 없으므로 어셈블리로 C를 실행할 준비를 한다.
 */
	.section .text.boot, "ax"
	.global _start
_start:
	/* 1. 코어 0만 진행하고 나머지 코어는 재운다 */
	mrs	x0, mpidr_el1
	and	x0, x0, #0xff		/* Aff0 = 코어 번호 */
	cbz	x0, primary
park:
	wfe
	b	park

primary:
	/* 2. 스택 설정 (SRAM) */
	ldr	x0, =__stack_top
	mov	sp, x0

	/* 3. .data 초깃값을 ROM에서 SRAM으로 복사 */
	ldr	x0, =__data_load
	ldr	x1, =__data_start
	ldr	x2, =__data_end
1:	cmp	x1, x2
	b.hs	2f
	ldr	x3, [x0], #8
	str	x3, [x1], #8
	b	1b

	/* 4. .bss를 0으로 채움 */
2:	ldr	x1, =__bss_start
	ldr	x2, =__bss_end
3:	cmp	x1, x2
	b.hs	4f
	str	xzr, [x1], #8
	b	3b

	/* 5. C 코드로 */
4:	bl	rom_main
	b	park
