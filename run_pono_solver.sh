#!/bin/bash

# Script to recursively find all .btor files and run Pono solver on each
# with a timeout of 3600 seconds (1 hour) and configurable parallelism

# Default number of parallel jobs (use number of CPU cores)
PARALLEL_JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -j|--jobs)
            PARALLEL_JOBS="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [-j|--jobs N]"
            echo "  -j, --jobs N    Number of parallel jobs (default: number of CPU cores)"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

echo "Running with $PARALLEL_JOBS parallel jobs"

# Create a directory to store logs
LOG_DIR="pono_ic3ng_bzla_solver_logs"
mkdir -p "$LOG_DIR"

# Find all .btor files recursively
echo "Finding all BTOR files (.btor)..."
BTOR_FILES=$(find . -name "*.btor")
TOTAL_FILES=$(echo "$BTOR_FILES" | wc -l)
echo "Found $TOTAL_FILES BTOR files."

# Counter for processed files
COUNTER=0
ACTIVE_JOBS=0

# Function to process a single file
process_file() {
    local FILE=$1
    local COUNTER=$2
    local TOTAL_FILES=$3
    
    # Extract filename without path and extension for log naming
    local FILENAME=$(basename "$FILE")
    local LOG_FILE="$LOG_DIR/${FILENAME%.*}_log.txt"
    
    echo "[$COUNTER/$TOTAL_FILES] Processing: $FILE"
    echo "Log will be saved to: $LOG_FILE"
    
    # Run Pono solver with timeout
    {
        # export .so library path
        export LD_LIBRARY_PATH=/data/guangyuh/coding_env/llm4pdr-ic3ng-predicate/build:$LD_LIBRARY_PATH
        echo "File: $FILE"
        echo "Command: /data/guangyuh/coding_env/llm4pdr-ic3ng-predicate/build/pono -e ic3ng-bits --smt-solver=bzla -k 10000 --promote-inputvars --external-predicates placeholder_predicate.smt2 --print-wall-time $FILE"
        echo "Started at: $(date)"
        echo "----------------------------------------"
        
        # Run the solver with timeout and capture output
        timeout 3600 /data/guangyuh/coding_env/llm4pdr-ic3ng-predicate/build/pono -e ic3ng-bits --smt-solver=bzla -k 10000 --promote-inputvars --external-predicates placeholder_predicate.smt2 --print-wall-time "$FILE" 2>&1
        
        # Check if the command timed out
        if [ $? -eq 124 ]; then
            echo "----------------------------------------"
            echo "STATUS: TIMEOUT (exceeded 3600 seconds)"
        else
            echo "----------------------------------------"
            echo "STATUS: COMPLETED"
        fi
        
        echo "Finished at: $(date)"
        echo "========================================"
    } > "$LOG_FILE"
    
    # Print progress (use flock to avoid interleaved output)
    {
        flock -x 200
        echo "Completed $COUNTER of $TOTAL_FILES files: $FILE"
        echo "----------------------------------------"
    } 200>"/tmp/pono_solver_lock"
}

# Create a lock file for synchronized output
touch "/tmp/pono_solver_lock"

# Process files in parallel with controlled concurrency
for FILE in $BTOR_FILES; do
    COUNTER=$((COUNTER + 1))
    
    # Wait if we've reached the maximum number of parallel jobs
    while [ $ACTIVE_JOBS -ge $PARALLEL_JOBS ]; do
        # Wait for any child process to finish
        wait -n 2>/dev/null || true
        ACTIVE_JOBS=$((ACTIVE_JOBS - 1))
    done
    
    # Process the file in the background
    process_file "$FILE" "$COUNTER" "$TOTAL_FILES" &
    ACTIVE_JOBS=$((ACTIVE_JOBS + 1))
done

# Wait for all remaining jobs to finish
wait

echo "All files processed. Logs are stored in the $LOG_DIR directory."

# Clean up
rm -f "/tmp/pono_solver_lock"