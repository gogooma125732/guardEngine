#include "../common.h"
#include "monitor.h"

#define STACK_LIMIT 50

uintptr_t shadow_stack[STACK_LIMIT];
int top = -1;

void push_return_addr(uintptr_t addr)
{
    if (top < STACK_LIMIT - 1)
        shadow_stack[++top] = addr;
}

int verify_return_addr(uintptr_t current_addr)
{
    if (top == -1 || shadow_stack[top] != current_addr)
        return 0;
    top--;
    return 1;
}