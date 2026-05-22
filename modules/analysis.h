#ifndef ANALYSIS_H
#define ANALYSIS_H

#include "../common.h"

// 1. Heapsort 관련: 로그 위험도 정렬
void sort_logs_by_severity(SecurityEvent *events[], int n);

// 2. Dijkstra 관련: 네트워크 취약 경로 분석
void analyze_network_attack_path(int start_node, int target_node, Graph *graph);

#endif
