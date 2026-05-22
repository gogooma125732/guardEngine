#include "detection.h"
#include "../common.h"

#define TABLE_SIZE 1024

typedef struct HashNode
{
    char name[64];
    struct HashNode *next;
} HashNode;

HashNode *table[TABLE_SIZE];

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
    newNode->next = table[idx];
    table[idx] = newNode;
}

int is_blacklisted(char *name)
{
    unsigned int idx = hash(name);
    HashNode *curr = table[idx];
    while (curr)
    {
        if (strcmp(curr->name, name) == 0)
            return 1;
        curr = curr->next;
    }
    return 0;
}