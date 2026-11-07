#include "uart.h"
#include "arch.h"

static const char banner[] = "\n[ROM] Hello from ROM!\n"; /* .rodata: ROM에 그대로 */
static uint32_t magic = 0x1234abcd;  /* .data: ROM에 저장, 부팅 때 SRAM으로 복사 */
static uint32_t counter;             /* .bss : SRAM, 0으로 시작 */

void rom_main(void)
{
	uart_init(UART0_BASE);
	print(banner);

	print("[ROM] CurrentEL = EL");
	print_dec(current_el());

	print("\n[ROM] rom_main  @ ");
	print_hex((uintptr_t)rom_main);
	print("\n[ROM] banner    @ ");
	print_hex((uintptr_t)banner);
	print("\n[ROM] magic     @ ");
	print_hex((uintptr_t)&magic);
	print(" = ");
	print_hex(magic);
	print("\n[ROM] counter   @ ");
	print_hex((uintptr_t)&counter);
	print(" = ");
	print_dec(counter);

	counter += 3; /* SRAM이라 값을 바꿀 수 있다 */
	print("\n[ROM] counter after += 3 : ");
	print_dec(counter);
	print("\n[ROM] done. (Ctrl-A X to quit)\n");

	halt();
}
