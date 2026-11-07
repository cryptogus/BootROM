#include "uart.h"

/* PL011 레지스터 오프셋 */
#define DR   0x00 /* 데이터 */
#define FR   0x18 /* 상태 플래그 */
#define IBRD 0x24 /* 보레이트 정수부 */
#define FBRD 0x28 /* 보레이트 소수부 */
#define LCRH 0x2c /* 라인 제어 */
#define CR   0x30 /* 제어 */

#define FR_RXFE (1u << 4) /* 수신 FIFO 비었음 */
#define FR_TXFF (1u << 5) /* 송신 FIFO 가득 참 */

static inline void reg_write(uintptr_t base, uint32_t off, uint32_t val)
{
	*(volatile uint32_t *)(base + off) = val;
}

static inline uint32_t reg_read(uintptr_t base, uint32_t off)
{
	return *(volatile uint32_t *)(base + off);
}

void uart_init(uintptr_t base)
{
	reg_write(base, CR, 0);                          /* 설정하는 동안 끄기 */
	reg_write(base, IBRD, 13);                       /* 24MHz / (16 x 115200) = 13.02 */
	reg_write(base, FBRD, 1);
	reg_write(base, LCRH, (3u << 5) | (1u << 4));    /* 8비트, FIFO 사용 */
	reg_write(base, CR, (1u << 9) | (1u << 8) | 1u); /* RXE | TXE | UARTEN */
}

void uart_putc(uintptr_t base, char c)
{
	while (reg_read(base, FR) & FR_TXFF)
		;
	reg_write(base, DR, (uint8_t)c);
}

int uart_getc(uintptr_t base)
{
	while (reg_read(base, FR) & FR_RXFE)
		;
	return reg_read(base, DR) & 0xff;
}

void print(const char *s)
{
	while (*s) {
		if (*s == '\n')
			uart_putc(UART0_BASE, '\r');
		uart_putc(UART0_BASE, *s++);
	}
}

void print_hex(uint64_t v)
{
	static const char digits[] = "0123456789abcdef";
	char buf[19];
	int n = (v >> 32) ? 16 : 8; /* 32비트에 들어가면 8자리만 */
	int i;

	buf[0] = '0';
	buf[1] = 'x';
	for (i = 0; i < n; i++)
		buf[1 + n - i] = digits[(v >> (i * 4)) & 0xf];
	buf[2 + n] = '\0';
	print(buf);
}

void print_dec(uint64_t v)
{
	char buf[21];
	int i = 20;

	buf[i] = '\0';
	do {
		buf[--i] = '0' + v % 10;
		v /= 10;
	} while (v);
	print(&buf[i]);
}
