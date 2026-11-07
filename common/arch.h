#ifndef ARCH_H
#define ARCH_H

#include <stdint.h>

/* 지금 실행 중인 Exception Level (0~3) */
static inline unsigned int current_el(void)
{
	uint64_t v;

	asm volatile("mrs %0, CurrentEL" : "=r"(v));
	return (v >> 2) & 3;
}

/* 더 할 일이 없을 때 CPU를 재운다 */
static inline __attribute__((noreturn)) void halt(void)
{
	for (;;)
		asm volatile("wfe");
}

#endif
