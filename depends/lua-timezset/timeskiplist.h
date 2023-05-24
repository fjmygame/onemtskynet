//
#include <stdlib.h>

#define SKIPLIST_MAXLEVEL 32
#define SKIPLIST_P 0.25

typedef struct tslobj
{
    double timestamp; // 时间戳，score相同的情况下，用时间戳排序，小的靠前
    char *ptr;
    size_t length;
} tslobj;

typedef struct tskiplistNode
{
    tslobj *obj;
    double score;
    struct tskiplistNode *backward;
    struct skiplistLevel
    {
        struct tskiplistNode *forward;
        unsigned int span;
    } level[];
} tskiplistNode;

typedef struct tskiplist
{
    struct tskiplistNode *header, *tail;
    unsigned long length;
    int level;
} tskiplist;

typedef void (*slDeleteCb)(void *ud, tslobj *obj);
typedef void (*slDumpCb)(void *ud, int index, double score, tslobj *obj);
tslobj *slCreateObj(const char *ptr, size_t length, double timestamp);
void slFreeObj(tslobj *obj);

tskiplist *slCreate(void);
void slFree(tskiplist *sl);
void slDump(tskiplist *sl);
void slDumpOut(tskiplist *sl, slDumpCb cb, void *ud);

void slInsert(tskiplist *sl, double score, tslobj *obj);
int slDelete(tskiplist *sl, double score, tslobj *obj);
unsigned long slDeleteByRank(tskiplist *sl, unsigned int start, unsigned int end, slDeleteCb cb, void *ud);

unsigned long slGetRank(tskiplist *sl, double score, tslobj *o);
tskiplistNode *slGetNodeByRank(tskiplist *sl, unsigned long rank);

tskiplistNode *slFirstInRange(tskiplist *sl, double min, double max);
tskiplistNode *slLastInRange(tskiplist *sl, double min, double max);
