#ifndef COMMON_H
#define COMMON_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <limits.h>

#define MAX_PATH 256
#define MAX_VERTICES 100

// 보안 이벤트 구조체
typedef struct
{
    int pid;
    int severity;
    char msg[128];
    char timestamp[32];
    char resource_path[MAX_PATH];
    char action[16];
} SecurityEvent;

// --- 그래프 및 다익스트라용 구조체 ---
typedef struct AdjListNode
{
    int dest;
    int weight;
    struct AdjListNode *next;
} AdjListNode;

typedef struct MinHeapNode
{
    int vertex;
    int dist;
} MinHeapNode;

typedef struct MinHeap
{
    int size;
    int capacity;
    int *pos;
    MinHeapNode **array;
} MinHeap;

typedef struct Graph
{
    int V;
    AdjListNode **adj;
} Graph;

MinHeap *createMinHeap(int capacity);
void decreaseKey(MinHeap *minHeap, int v, int dist);
MinHeapNode *extractMin(MinHeap *minHeap);
int isInMinHeap(MinHeap *minHeap, int v);

#endif