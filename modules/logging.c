#include "logging.h"
#include "../common.h"
#include <time.h>

typedef struct LogNode
{
    SecurityEvent event;
    struct LogNode *prev, *next;
} LogNode;

LogNode *head = NULL, *tail = NULL;
int count = 0;
#define MAX_LOG_SIZE 100

void log_activity(int pid, char *path, char *action, int severity)
{
    LogNode *newNode = (LogNode *)malloc(sizeof(LogNode));
    newNode->event.pid = pid;
    newNode->event.severity = severity;
    strncpy(newNode->event.resource_path, path, MAX_PATH);
    strncpy(newNode->event.action, action, 16);

    newNode->next = head;
    newNode->prev = NULL;
    if (head)
        head->prev = newNode;
    head = newNode;
    if (!tail)
        tail = newNode;

    if (++count > MAX_LOG_SIZE)
    {
        LogNode *temp = tail;
        tail = tail->prev;
        if (tail)
            tail->next = NULL;
        free(temp);
        count--;
    }
}

int detect_ransomware_activity(int target_pid)
{
    int write_count = 0;
    LogNode *curr = head;

    int search_limit = 20;
    while (curr != NULL && search_limit--)
    {
        if (curr->event.pid == target_pid && strcmp(curr->event.action, "WRITE") == 0)
        {
            write_count++;
        }
        curr = curr->next;
    }

    if (write_count >= 5)
        return 1;
    return 0;
}

int get_all_logs(SecurityEvent *dest[])
{
    int i = 0;
    LogNode *curr = head;
    while (curr != NULL && i < MAX_LOG_SIZE)
    {
        dest[i++] = &(curr->event);
        curr = curr->next;
    }
    return i;
}