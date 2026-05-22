#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>

#include "common.h"
#include "modules/detection.h"
#include "modules/logging.h"
#include "modules/monitor.h"
#include "modules/response.h"
#include "modules/analysis.h"

#define TABLE_SIZE 10
#define MAX_LOG_SIZE 5
#define MAX_HEAP 20

#define POLICY_CRITICAL_SEVERITY 95
#define POLICY_NORMAL_SEVERITY 10
#define RANSOMWARE_THRESHOLD 5

int main(int argc, char *argv[])
{
    if (argc < 2)
    {
        printf("\n[USAGE] %s <file_path>\n", argv[0]);
        printf("Example: %s /etc/passwd\n\n", argv[0]);
        return 1;
    }

    add_to_blacklist("/etc/shadow");
    add_to_blacklist("/etc/passwd");
    add_to_blacklist("/root/.ssh/id_rsa");

    char *target_path = argv[1];
    int my_pid = getpid();
    int current_severity = POLICY_NORMAL_SEVERITY;
    char *current_action = "READ"; // 기본 동작 설정

    printf("\n[SYSTEM] Guard Engine initialized (PID: %d)\n", my_pid);
    printf("[MONITOR] Analyzing resource: %s\n", target_path);

    if (access(target_path, F_OK) != 0)
    {
        printf("[ERROR] Target file does not exist on disk: %s\n", target_path);
        return 1;
    }

    struct stat file_info;
    struct stat st;
    stat(target_path, &file_info); // 실제 파일의 메타데이터(크기 등) 획득
    printf("[MONITOR] Starting System Guard Engine for PID: %d\n", my_pid);
    printf("[MONITOR] Target file found. Size: %lld bytes\n", file_info.st_size);
    printf("[MONITOR] Accessing resource: %s\n", target_path);

    if (access(target_path, F_OK) != 0)
    {
        printf("[WARNING] Target resource '%s' not found on physical disk.\n", target_path);
        printf("[SYSTEM] Proceeding with virtual simulation mode...\n");
    }
    else
    {
        if (stat(target_path, &st) == 0)
        {
            printf("[MONITOR] Physical resource verified. Size: %lld bytes\n", (long long)st.st_size);
        }
    }

    // 시나리오 A: 정적 블랙리스트 탐지 (Hash Table 활용)
    if (is_blacklisted(target_path))
    {
        current_severity = POLICY_CRITICAL_SEVERITY;
        current_action = "ILLEGAL_ACCESS";

        printf("[ALERT] Static Policy Violation: Blacklisted resource access!\n");
        push_threat(my_pid, current_severity); // Max-Heap에 위협 추가
        log_activity(my_pid, target_path, current_action, current_severity);
    }
    else
    {
        printf("[INFO] Static Policy Check: Passed.\n");
        log_activity(my_pid, target_path, current_action, current_severity);
    }

    // 시나리오 B: 동적 행위 분석 (Double Linked List & 윈도우 기반 탐지)
    // 공격 시나리오 시뮬레이션을 위해 연속적인 WRITE 발생
    printf("[SIMULATION] Executing file modification tasks...\n");
    for (int i = 0; i < RANSOMWARE_THRESHOLD; i++)
    {
        log_activity(my_pid, target_path, "WRITE", current_severity);
    }

    if (detect_ransomware_activity(my_pid))
    {
        printf("[CRITICAL] Dynamic Policy Violation: Ransomware behavior detected!\n");
        printf("[CRITICAL] High frequency of WRITE actions from PID %d\n", my_pid);

        push_threat(my_pid, 100); // 최고 우선순위 위협 발생
        handle_top_threat();      // 즉각적인 위협 대응 로직 호출 (Down-Heap)
    }

    //  사후 분석 및 리포트 생성
    SecurityEvent *log_array[MAX_LOG_SIZE];
    int log_count = get_all_logs(log_array);

    if (log_count > 0)
    {
        sort_logs_by_severity(log_array, log_count);

        printf("\n======================================================\n");
        printf("       SECURITY ANALYSIS REPORT (Sorted by Risk)      \n");
        printf("======================================================\n");
        for (int i = 0; i < log_count; i++)
        {
            printf("[%d] Priority: %-3d | Action: %-14s | Resource: %s\n",
                   i + 1, log_array[i]->severity, log_array[i]->action, log_array[i]->resource_path);
        }
        printf("======================================================\n");
    }

    return 0;
}