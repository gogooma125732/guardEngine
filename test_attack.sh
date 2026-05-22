#!/bin/bash

# Clean Up
echo "[1/4] Cleaning up previous builds..."
rm -f guard_engine normal_file.txt sensitive_data.tmp

# Rebuild
echo "[2/4] Recompiling Security Engine with new policy..."
gcc -o guard_engine main.c modules/detection.c modules/logging.c modules/monitor.c modules/response.c modules/analysis.c -I.

if [ $? -ne 0 ]; then
    echo "[ERROR] Compilation failed. Please check your code."
    exit 1
fi

echo "[3/4] Preparing test resources..."
echo "This is a normal document." > normal_file.txt
echo "Critical system configuration" > sensitive_data.tmp

echo -e "[4/4] Starting Attack Scenarios...\n"

echo ">> SCENARIO 1: Accessing Blacklisted System File (/etc/passwd)"
./guard_engine /etc/passwd

echo -e "\n>> SCENARIO 2: Accessing Normal File (Logging Test)"
./guard_engine normal_file.txt

echo -e "\n>> SCENARIO 3: Ransomware Behavior Simulation"
./guard_engine sensitive_data.tmp

echo -e "\n[INFO] All scenarios completed. Check the Analysis Report above."
