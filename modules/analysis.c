#include "../common.h"
#include "analysis.h"
#include <limits.h>

void event_heapify(SecurityEvent *arr[], int n, int i)
{
    int largest = i;
    int left = 2 * i + 1;
    int right = 2 * i + 2;

    if (left < n && arr[left]->severity > arr[largest]->severity)
        largest = left;

    if (right < n && arr[right]->severity > arr[largest]->severity)
        largest = right;

    if (largest != i)
    {
        SecurityEvent *temp = arr[i];
        arr[i] = arr[largest];
        arr[largest] = temp;
        event_heapify(arr, n, largest);
    }
}

void sort_logs_by_severity(SecurityEvent *events[], int n)
{
    for (int i = n / 2 - 1; i >= 0; i--)
    {
        event_heapify(events, n, i);
    }

    for (int i = n - 1; i > 0; i--)
    {
        SecurityEvent *temp = events[0];
        events[0] = events[i];
        events[i] = temp;
        event_heapify(events, i, 0);
    }
}

void analyze_network_attack_path(int start_node, int target_node, Graph *graph)
{
    int V = graph->V;
    int dist[V];
    MinHeap *minHeap = createMinHeap(V);

    // 초기화
    for (int v = 0; v < V; ++v)
    {
        dist[v] = INT_MAX;
        minHeap->array[v] = (MinHeapNode *)malloc(sizeof(MinHeapNode));
        minHeap->array[v]->vertex = v;
        minHeap->array[v]->dist = INT_MAX;
        minHeap->pos[v] = v;
    }

    dist[start_node] = 0;
    decreaseKey(minHeap, start_node, 0);
    minHeap->size = V;

    while (minHeap->size != 0)
    {
        MinHeapNode *minNode = extractMin(minHeap);
        int u = minNode->vertex;

        AdjListNode *pCrawl = graph->adj[u];
        while (pCrawl != NULL)
        {
            int v = pCrawl->dest;
            if (isInMinHeap(minHeap, v) && dist[u] != INT_MAX &&
                pCrawl->weight + dist[u] < dist[v])
            {
                dist[v] = dist[u] + pCrawl->weight;
                decreaseKey(minHeap, v, dist[v]);
            }
            pCrawl = pCrawl->next;
        }
        free(minNode);
    }

    printf("\n[REPORT] Risk Path Analysis from Node %d to Target %d: Distance %d\n",
           start_node, target_node, dist[target_node]);
}

MinHeap *createMinHeap(int capacity)
{
    MinHeap *minHeap = (MinHeap *)malloc(sizeof(MinHeap));
    minHeap->pos = (int *)malloc(capacity * sizeof(int));
    minHeap->size = 0;
    minHeap->capacity = capacity;
    minHeap->array = (MinHeapNode **)malloc(capacity * sizeof(MinHeapNode *));
    return minHeap;
}

void decreaseKey(MinHeap *minHeap, int v, int dist)
{
    int i = minHeap->pos[v];
    minHeap->array[i]->dist = dist;
    while (i && minHeap->array[i]->dist < minHeap->array[(i - 1) / 2]->dist)
    {
        minHeap->pos[minHeap->array[i]->vertex] = (i - 1) / 2;
        minHeap->pos[minHeap->array[(i - 1) / 2]->vertex] = i;
        MinHeapNode *temp = minHeap->array[i];
        minHeap->array[i] = minHeap->array[(i - 1) / 2];
        minHeap->array[(i - 1) / 2] = temp;
        i = (i - 1) / 2;
    }
}

MinHeapNode *extractMin(MinHeap *minHeap)
{
    if (minHeap->size == 0)
        return NULL;
    MinHeapNode *root = minHeap->array[0];
    MinHeapNode *lastNode = minHeap->array[minHeap->size - 1];
    minHeap->array[0] = lastNode;
    minHeap->pos[root->vertex] = minHeap->size - 1;
    minHeap->pos[lastNode->vertex] = 0;
    --minHeap->size;
    // minHeapify 과정은 생략 가능하나 필요시 구현 추가
    return root;
}

int isInMinHeap(MinHeap *minHeap, int v)
{
    return minHeap->pos[v] < minHeap->size;
}