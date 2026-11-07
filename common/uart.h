#ifndef UART_H
#define UART_H

#include <stdint.h>

#define UART0_BASE 0x09000000UL /* 콘솔: 터미널에 연결됨 */
#define UART1_BASE 0x09040000UL /* 다운로드 포트: secure UART (3장) */

void uart_init(uintptr_t base);
void uart_putc(uintptr_t base, char c);
int uart_getc(uintptr_t base); /* 한 글자가 올 때까지 기다린다 */

/* 콘솔(UART0) 출력 도우미 */
void print(const char *s);
void print_hex(uint64_t v);
void print_dec(uint64_t v);

#endif
