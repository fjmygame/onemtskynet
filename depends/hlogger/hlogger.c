/*
 * Create Date:2023-03-25 09:02:43
 * Author  : Happy Su
 * Version : 1.0
 * Filename: hlogger.c
 * Introduce  : 类介绍
 */

#include "hlogger.h"
#include "skynet.h"
#include "skynet_env.h"

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <time.h>


#define SZ_LONG_64 (64)
#define SZ_LONG_128 (SZ_LONG_64*2)
#define SZ_LONG_256 (SZ_LONG_128*2)
#define ONE_MB (1024*1024)
#define ONE_G (ONE_MB*1024)

#define SZ_LOGGERS (4) /* logger可用的最大ID*/
#define SZ_FILE_BFF (10*ONE_MB) /* 缓冲区大小*/
#define SZ_FILE_NAME (SZ_LONG_64) /* 文件名长度*/
#define SZ_FILE_PATH (SZ_LONG_256) /* 文件路径长度*/

#define VALID_CLOGFILE(file) (file != NULL && file != stdout) /* 检查文件句柄 */
#define RETURN_CLOGERR_CLOSE_LOGGER(logger, msg, errno, rtr) {throwErrorItem((logger), (msg), (errno));return (rtr);}
#define RETURN_CLOGERR_SOME(inst, msg, errno, rtr) {throwError((inst), (msg), (errno));return (rtr);}

static const char * logger_names[] = {"error", "warn", "info", "debug", NULL};
typedef enum {ERROR = 0,WARN,INFO,LoggerLevelNull} LoggerLevel;

struct LoggerItem {
    FILE* file; /* 日志文件句柄 */
    int fwrited; /* 已写入文件大小 */
    char fnamepre[SZ_FILE_NAME]; /* 文件名前缀 */
    char filepath[SZ_FILE_PATH]; /* 全路径 */
};

typedef struct {
    int fsize; /* 单文件大小 */
    int mday; /* 日 */
    char dir[SZ_FILE_PATH]; /* 目录名 */
    struct LoggerItem loggers[SZ_LOGGERS]; /* 日志文件句柄 */
} HappyLogger;


// return nsec
static int64_t
get_time() {
#if !defined(__APPLE__) || defined(AVAILABLE_MAC_OS_X_VERSION_10_12_AND_LATER)
	struct timespec ti;
	clock_gettime(CLOCK_REALTIME, &ti);
	return (int64_t)1000000000 * ti.tv_sec + ti.tv_nsec;
#else
	struct timeval tv;
	gettimeofday(&tv, NULL);
	return (int64_t)1000000000 * tv.tv_sec + tv.tv_usec * 1000;
#endif
}

static int
get_time_mday(time_t timestamp) {
    if (timestamp == 0) {
        time(&timestamp);
    }
    struct tm* date = localtime(&timestamp); // 将时间戳转换为日期时间结构体
    return date->tm_mday;
}


static void
closeFile(struct LoggerItem* logger) {
    if (VALID_CLOGFILE(logger->file)) {
        fflush(logger->file);
        fclose(logger->file);
        printf("closeFile %s\n", logger->filepath);
    }
    logger->file = stdout;
}

static void
closeAllFiles(HappyLogger *inst) {
    int i;
    for (i = 0; i < SZ_LOGGERS; ++i)
        closeFile(&inst->loggers[i]);
}

static  void
throwErrorItem(struct LoggerItem* logger, const char* msg, int* saved_errno) {
    fprintf(stderr, "%s error[%d]: %s\n", msg, *saved_errno, strerror(*saved_errno));
    closeFile(logger);
}

static  void
throwError(HappyLogger *inst, const char* msg, int* saved_errno) {
    fprintf(stderr, "%s error[%d]: %s\n", msg, *saved_errno, strerror(*saved_errno));
    closeAllFiles(inst);
}

static  char
newDir(HappyLogger *inst, const char* strdir, int mode) {
    int len, i;
    char temp[SZ_FILE_PATH];

    if (0 == access(strdir, F_OK)) return 1;
    
    memset(temp, 0, sizeof(temp));
    len = strlen(strdir);
    strncpy(temp, strdir, len);

    for (i = 1; i < len; i++) { /* i=1,因为首字符可能是 */
        if (temp[i] != '/') continue;

        temp[i] = '\0';
        if (0 == access(temp, F_OK) || 0 == mkdir(temp, mode)) {
            temp[i] = '/';
            continue;
        }

        printf("for new dir error %s\n", temp);
        RETURN_CLOGERR_SOME(inst, "for new dir", &errno, 0);
    }

    if (0 != mkdir(strdir, mode)) {
        printf("new dir error %s\n", strdir);
        RETURN_CLOGERR_SOME(inst, "new dir", &errno, 0);
    }

    return 1;
}

static void
completeFilePath(HappyLogger *inst, struct LoggerItem* logger) {
    /* printf("pathpill start filepath: %s index:%d \n", filepath, index); */
    time_t now;
    struct tm local_time;
    char date[SZ_LONG_64];
    time(&now);                    /* 获取当前时间 */
    localtime_r(&now, &local_time);/* 转换为本地时间 */
    strftime(date, sizeof(date), "%Y-%m-%d_%H-%M-%S", &local_time); /* 转换为字符串 */
    snprintf(logger->filepath, SZ_FILE_PATH, "%s/%s_%s_%d.log", inst->dir, logger->fnamepre, date, getpid());
    /* printf("pathpill filepath: %s \n", filepath); */
}

static int
createLoggerFile(HappyLogger *inst, struct LoggerItem* logger) {
    /* 计算当前文件路径 */
    completeFilePath(inst, logger);
    printf("createLoggerFile %s \n", logger->filepath);
    if (VALID_CLOGFILE(logger->file))
        logger->file = freopen(logger->filepath, "a+", logger->file);
    else
        logger->file = fopen(logger->filepath, "a+");

    if (logger->file == NULL) {
        if (errno != ENOENT)
            RETURN_CLOGERR_SOME(inst, "new file", &errno, 1);

        if (!newDir(inst, inst->dir, 0755)) return 1;

        logger->file = fopen(logger->filepath, "a+");
        if (logger->file == NULL)
            RETURN_CLOGERR_SOME(inst, "new file fopen", &errno, 1);
    }

    /* debug模式下，采用行缓冲_IOLBF，否则采用全缓冲(_IOFBF) */
    setvbuf(logger->file, NULL, _IOFBF, SZ_FILE_BFF);
    logger->fwrited = 0;

    return 0;
}

static int
rollFile(HappyLogger *inst, struct LoggerItem* logger) {
    printf("rollFile:%s filePath:%s size:%d\n", logger->fnamepre, logger->filepath, logger->fwrited);
    closeFile(logger);
    
    /* 创建一个新文件 */
    return createLoggerFile(inst, logger);
}

/* 日志落地 */
static int logger_output(HappyLogger *inst, LoggerLevel eValue, uint32_t source, double time_nmic, const char* msg, size_t sz) {
    struct LoggerItem* logger;
    int write_sz_1, write_sz_2, write_sz_3;

    if (eValue >= LoggerLevelNull || eValue < 0) return 1;

    logger = &inst->loggers[eValue];
    if (logger == NULL) return 0;

    if (!VALID_CLOGFILE(logger->file)) {
        // 如果文件创建失败了，退出
        if (createLoggerFile(inst, logger)) return 1;
    }

    if (logger->fwrited > inst->fsize) {
        // 如果文件创建失败了，退出
        if (rollFile(inst, logger)) return 1;
    }

    /* 写入日志 */
    write_sz_1 = fprintf(logger->file, "[:%08x] (%.3f)", source, time_nmic);
    if (write_sz_1 < 0 ) {
        RETURN_CLOGERR_CLOSE_LOGGER(logger, "fprintf write_sz_1 err", &errno, 0)
    }
    write_sz_2 = fwrite(msg, sizeof(char), sz, logger->file);
    if (write_sz_2 < 0) {
        RETURN_CLOGERR_CLOSE_LOGGER(logger, "fwrite err", &errno, 0)
    }
    write_sz_3 = fprintf(logger->file, "\n");
    if (write_sz_3 < 0) {
        RETURN_CLOGERR_CLOSE_LOGGER(logger, "fprintf write_sz_3 err", &errno, 0)
    }
    fflush(logger->file);
    logger->fwrited += write_sz_1 + write_sz_2 + write_sz_3;

    // printf("file:%s had write %d bytes\n", logger->filepath, logger->fwrited);
	return 0;
}

/* ----------------- 以下为skynet服务接口 ----------------- */
HappyLogger*
hlogger_create(void) {
    HappyLogger *inst;
    printf("hlogger_create\n");
    inst = skynet_malloc(sizeof(*inst));
    memset(inst, 0, sizeof(*inst));    
    return inst;
}

void
hlogger_release(HappyLogger * inst) {
    printf("hlogger_release\n");
    /* 关闭所有文档 */
	closeAllFiles(inst);
    /* 释放内存 */
	skynet_free(inst);
}

static int
hlogger_cb(struct skynet_context * context, void *ud, int type, int session, uint32_t source, const void * msg, size_t sz) {
    double time_nmic;
    int cur_mday;
    HappyLogger *inst = (HappyLogger*)ud;
    time_nmic = ((double)get_time())/1000000000;

    // 检查是否跨天
    cur_mday = get_time_mday((time_t)time_nmic);
    if (inst->mday != cur_mday) {
        inst->mday = cur_mday;
        closeAllFiles(inst);
    }

	switch (type) {
	case PTYPE_SYSTEM:
		/* todos reopen signal */
		break;
	case PTYPE_TEXT: /* skynet.error 接口传进来，直接调用info接口 */
    case PTYPE_LOG_INFO:
    case PTYPE_LOG_DEBUG:        
        printf("[:%08x] (%.3f) %s\n",source, time_nmic, (char *)msg);
        logger_output(inst, INFO, source, time_nmic, msg, sz);	
		break;
    case PTYPE_LOG_ERROR:
        printf("[:%08x] (%.3f) %s\n",source, time_nmic, (char *)msg);
        /* 错误级别的日志，在error和info接口中都会调用 */
        logger_output(inst, ERROR, source, time_nmic, msg, sz);
        logger_output(inst, INFO, source, time_nmic, msg, sz);
        break;
    case PTYPE_LOG_WARN:
        printf("[:%08x] (%.3f) %s\n",source, time_nmic, (char *)msg);
        logger_output(inst, WARN, source, time_nmic, msg, sz);
        logger_output(inst, INFO, source, time_nmic, msg, sz);
        break;
	}

	return 0;
}

/* 读取配置文件，设置日志配置 */
int
hlogger_read_config(HappyLogger * inst) {
    char config_path[SZ_LONG_128] = "./game/bootstrap/hlogger.config";
    const char * servertype = skynet_getenv("servertype");
    char patten[SZ_LONG_64];
    char line[SZ_LONG_128];    
    FILE *fp;


	if (servertype == NULL) {
        perror("un set env servertype");
        return 1;
    }
    /* 如果存在指定配置 */
    if (0 != access(config_path, R_OK)) {
        perror("config_path read faild");
        return 1;
    }

    fp = fopen(config_path, "r");
    if (fp == NULL) {
        perror("hlogger_read_config fopen error");
        return 1;
    }

    sprintf(patten, "%s_logpath=", servertype);
    while (fgets(line, sizeof(line), fp)) {
        if (strstr(line, patten) == line) {
            char *value_start, *pn;
            value_start = line + strlen(patten);
            strncpy(inst->dir, value_start, strlen(value_start) + 1);
            pn = strchr(inst->dir, '\n');
            if (pn) {
                *pn = '\0';
            }
            printf("hlogger_init from config dir:%s\n", inst->dir);
            return 0;
        }
    }

    return 1;
}

int
hlogger_init(HappyLogger * inst, struct skynet_context *ctx, const char * parm) {
    /* 获取当前工作目录 */
    char cwd[SZ_FILE_PATH], err[SZ_LONG_256], *p;
    int i;
    int mday;
    int64_t time_micro = get_time();
    /* 如果没有专门指定log路径，走参数拼接 */
    if (0 != hlogger_read_config(inst)) {
        const char * logpath = skynet_getenv("logpath");
        if (logpath == NULL) {
            perror("hlogger_init logpath is null\n");
            return 1;
        }
        
        if (getcwd(cwd, sizeof(cwd)) != NULL) {
            printf("Current working directory: %s\n", cwd);
        } else {
            perror("getcwd() error");
            return 1;
        }
        /* 截取当前路径的最后一段 */
        p = strrchr(cwd, '/');
        if (p == NULL) {
            strcpy(inst->dir, logpath);
        } else {
            /* 拼接保存路径 */
            sprintf(inst->dir, "%s%s", logpath, p);
        }
    }
    
    printf("hlogger_init dir:%s\n", inst->dir);   

    /* 创建目录 */
    if (!newDir(inst, inst->dir, 0755)) {
        sprintf(err, "create dir %s error", inst->dir);
        perror(err);
        return 1;
    }
    printf("create dir %s success\n", inst->dir);

    /* 单个文件最大1G */
    inst->fsize = ONE_G;
    mday = get_time_mday((time_t)(((double)time_micro)/1000000000));
    printf("cur mday is:%d time_micro:%lld\n", mday, time_micro);
    /* 0点时间戳 */
    inst->mday = mday;
    /* 拼接文件路径，创建文件 */
    for (i = 0; i < SZ_LOGGERS; ++i) {
        strcpy(inst->loggers[i].fnamepre, logger_names[i]);
    }

	skynet_callback(ctx, inst, hlogger_cb);
    printf("skynet_callback hlogger_cb\n");

	return 0;
}
