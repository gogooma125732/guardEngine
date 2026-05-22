#include "../common.h"
#include "response.h"

SecurityEvent heap[200];
int heap_size = 0;

void push_threat(int pid, int severity)
{
    heap[++heap_size] = (SecurityEvent){pid, severity, "THREAT_DETECTED", ""};
    int i = heap_size;
    while (i > 1 && heap[i].severity > heap[i / 2].severity)
    {
        SecurityEvent tmp = heap[i];
        heap[i] = heap[i / 2];
        heap[i / 2] = tmp;
        i /= 2;
    }
}

void handle_top_threat()
{
    if (heap_size == 0)
        return;
    SecurityEvent top = heap[1];
    printf("[RESPONSE] Terminating Critical Threat: PID %d (Sev: %d)\n", top.pid, top.severity);
}