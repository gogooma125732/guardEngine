#include "../common.h"

#ifndef MONITOR_H
#define MONITOR_H

void push_return_addr(uintptr_t addr);
int verify_return_addr(uintptr_t current_addr);

#endif
