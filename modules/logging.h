#include "../common.h"

#ifndef LOGGING_H
#define LOGGING_H

void log_activity(int pid, char *path, char *action, int severity);
int detect_ransomware_activity(int target_pid);
int get_all_logs(SecurityEvent *dest[]);

#endif
