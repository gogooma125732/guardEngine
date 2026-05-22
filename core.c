#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TABLE_SIZE 10
#define MAX_LOGS 5
#define MAX_HEAP 20

// 1. [Hash Table] 블랙리스트 탐지용
typedef struct HashNode
{
    char name[32];
    struct HashNode *next;
} HashNode;

HashNode *blacklist[TABLE_SIZE];

unsigned int hash(char *str)
{
    unsigned int h = 0;
    while (*str)
        h = (h << 5) + *str++;
    return h % TABLE_SIZE;
}

void add_to_blacklist(char *name)
{
    unsigned int idx = hash(name);
    HashNode *newNode = (HashNode *)malloc(sizeof(HashNode));
    strcpy(newNode->name, name);
    newNode->next = blacklist[idx];
    blacklist[idx] = newNode;
}

int check_blacklist(char *name)
{
    unsigned int idx = hash(name);
    HashNode *curr = blacklist[idx];
    while (curr)
    {
        if (strcmp(curr->name, name) == 0)
            return 1;
        curr = curr->next;
    }
    return 0;
}

// 2. [Double Linked List] 이벤트 로그 (LRU 방식)
typedef struct EventNode
{
    int pid;
    char msg[64];
    struct EventNode *prev, *next;
} EventNode;

EventNode *log_head = NULL, *log_tail = NULL;
int log_count = 0;

void log_event(int pid, char *msg)
{
    EventNode *newNode = (EventNode *)malloc(sizeof(EventNode));
    newNode->pid = pid;
    strcpy(newNode->msg, msg);
    newNode->next = log_head;
    newNode->prev = NULL;

    if (log_head)
        log_head->prev = newNode;
    log_head = newNode;
    if (!log_tail)
        log_tail = newNode;

    log_count++;
    if (log_count > MAX_LOGS)
    { // 오래된 로그 삭제 (Eviction)
        EventNode *temp = log_tail;
        log_tail = log_tail->prev;
        log_tail->next = NULL;
        free(temp);
        log_count--;
    }
    printf("[LOG] PID %d: %s\n", pid, msg);
}

// 3. [Stack] 함수 호출 흐름 검증 (Shadow Stack)
#define STACK_SIZE 10
typedef struct
{
    uintptr_t addr[STACK_SIZE];
    int top;
} ShadowStack;

void push_stack(ShadowStack *s, uintptr_t addr)
{
    if (s->top < STACK_SIZE - 1)
        s->addr[++(s->top)] = addr;
}

int verify_stack(ShadowStack *s, uintptr_t return_addr)
{
    if (s->top == -1 || s->addr[s->top] != return_addr)
        return 0; // 변조 탐지
    s->top--;
    return 1;
}

// 4. [Heap] 위협 우선순위 대응 (Max-Heap)
typedef struct
{
    int severity;
    int pid;
} Threat;

Threat heap[MAX_HEAP];
int heap_size = 0;

void push_threat(int sev, int pid)
{
    heap[++heap_size] = (Threat){sev, pid};
    int i = heap_size;
    while (i > 1 && heap[i].severity > heap[i / 2].severity)
    {
        Threat tmp = heap[i];
        heap[i] = heap[i / 2];
        heap[i / 2] = tmp;
        i /= 2;
    }
}

Threat pop_threat()
{
    Threat top = heap[1];
    heap[1] = heap[heap_size--];
    int i = 1;
    while (i * 2 <= heap_size)
    {
        int child = i * 2;
        if (child + 1 <= heap_size && heap[child + 1].severity > heap[child].severity)
            child++;
        if (heap[i].severity >= heap[child].severity)
            break;
        Threat tmp = heap[i];
        heap[i] = heap[child];
        heap[child] = tmp;
        i = child;
    }
    return top;
}

// --- 메인 보안 엔진 시뮬레이션 ---
int main()
{
    // 초기 설정: 블랙리스트 등록
    add_to_blacklist("malware.exe");
    add_to_blacklist("ransom_note.bin");

    printf("--- Security Engine Started ---\n");

    // 시나리오 1: 파일 실행 및 Hash 검사
    char *run_file = "malware.exe";
    if (check_blacklist(run_file))
    {
        printf("[ALERT] Blacklisted file detected: %s\n", run_file);
        push_threat(95, 1234); // 위험도 95로 Heap 삽입
    }

    // 시나리오 2: 로그 기록 (Double Linked List)
    log_event(1234, "Attempted to execute unauthorized file");
    log_event(5678, "Normal process started");

    // 시나리오 3: 함수 복귀 주소 검증 (Stack)
    ShadowStack s = {.top = -1};
    push_stack(&s, 0xDEADBEEF); // 정상 주소 저장

    uintptr_t fake_addr = 0xBAD00000; // 공격자에 의해 변조된 주소 가정
    if (!verify_stack(&s, fake_addr))
    {
        printf("[CRITICAL] Control Flow Integrity Violation in PID 1234!\n");
        push_threat(100, 1234); // 최상위 위험도 Heap 삽입
    }

    // 시나리오 4: 위협 대응 (Heap)
    if (heap_size > 0)
    {
        Threat t = pop_threat();
        printf("[RESPONSE] Terminating highest threat PID %d (Severity: %d)\n", t.pid, t.severity);
    }

    return 0;
}