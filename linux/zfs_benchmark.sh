#!/bin/bash
# ==========================================
# ZFS ZVOL / Filesystem FIO Test Script
# Usage:
#   ./zfstest.sh [testtype] [targetpath]
# Example:
#   ./zfstest.sh sync /mnt/zvol_test/testfile
#   ./zfstest.sh seqwrite /mnt/zvol_test/bigfile
# ==========================================

set -e

TEST="$1"
TARGET="$2"

if [[ -z "$TEST" || -z "$TARGET" ]]; then
  echo "Usage: $0 [sync|seqwrite|seqread|randrw|randread|randwrite|latency|mixed|all] [targetpath]"
  exit 1
fi

# Check if fio is installed
if ! command -v fio &> /dev/null; then
  echo "Error: fio is not installed. Please install it first."
  exit 1
fi

# Validate target directory exists (if it's a path with directory)
TARGET_DIR=$(dirname "$TARGET")
if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Error: Directory $TARGET_DIR does not exist."
  exit 1
fi

run_test() {
  local test_name="$1"
  echo "=========================================="
  echo "Running FIO test type: $test_name"
  echo "Target path: $TARGET"
  echo "Start time: $(date)"
  echo "=========================================="
}

cleanup_test() {
  echo "=========================================="
  echo "Test '$1' completed."
  echo "End time: $(date)"
  echo "=========================================="
  echo ""
}

case "$TEST" in
  sync)
    run_test "sync"
    fio --name=sync_write_test \
        --filename="$TARGET" \
        --rw=write \
        --bs=4k \
        --size=1G \
        --ioengine=sync \
        --fdatasync=1 \
        --numjobs=1 \
        --runtime=60 \
        --time_based \
        --group_reporting
    cleanup_test "sync"
    ;;

  seqwrite)
    run_test "seqwrite"
    fio --name=seq_write \
        --filename="$TARGET" \
        --rw=write \
        --bs=1M \
        --size=10G \
        --ioengine=libaio \
        --direct=1 \
        --numjobs=1 \
        --iodepth=32 \
        --runtime=60 \
        --time_based \
        --group_reporting
    cleanup_test "seqwrite"
    ;;

  seqread)
    run_test "seqread"
    fio --name=seq_read \
        --filename="$TARGET" \
        --rw=read \
        --bs=1M \
        --size=10G \
        --ioengine=libaio \
        --direct=1 \
        --numjobs=1 \
        --iodepth=32 \
        --runtime=60 \
        --time_based \
        --group_reporting
    cleanup_test "seqread"
    ;;

  randrw)
    run_test "randrw"
    fio --name=rand_rw \
        --filename="$TARGET" \
        --rw=randrw \
        --rwmixread=70 \
        --bs=4k \
        --size=2G \
        --ioengine=libaio \
        --direct=1 \
        --numjobs=4 \
        --iodepth=16 \
        --runtime=60 \
        --time_based \
        --group_reporting
    cleanup_test "randrw"
    ;;

  randread)
    run_test "randread"
    fio --name=rand_read \
        --filename="$TARGET" \
        --rw=randread \
        --bs=4k \
        --size=2G \
        --ioengine=libaio \
        --direct=1 \
        --numjobs=4 \
        --iodepth=16 \
        --runtime=60 \
        --time_based \
        --group_reporting
    cleanup_test "randread"
    ;;

  randwrite)
    run_test "randwrite"
    fio --name=rand_write \
        --filename="$TARGET" \
        --rw=randwrite \
        --bs=4k \
        --size=2G \
        --ioengine=libaio \
        --direct=1 \
        --numjobs=4 \
        --iodepth=16 \
        --runtime=60 \
        --time_based \
        --group_reporting
    cleanup_test "randwrite"
    ;;

  latency)
    run_test "latency"
    # Low queue depth test to measure latency accurately
    fio --name=latency_test \
        --filename="$TARGET" \
        --rw=randread \
        --bs=4k \
        --size=1G \
        --ioengine=libaio \
        --direct=1 \
        --numjobs=1 \
        --iodepth=1 \
        --runtime=60 \
        --time_based \
        --group_reporting \
        --percentile_list=50:90:95:99:99.9:99.99
    cleanup_test "latency"
    ;;

  mixed)
    run_test "mixed"
    # Database-like workload: mix of reads/writes with varying block sizes
    fio --name=mixed_workload \
        --filename="$TARGET" \
        --rw=randrw \
        --rwmixread=65 \
        --bs=8k \
        --size=5G \
        --ioengine=libaio \
        --direct=1 \
        --numjobs=8 \
        --iodepth=32 \
        --runtime=120 \
        --time_based \
        --group_reporting \
        --norandommap
    cleanup_test "mixed"
    ;;

  all)
    echo "Running ALL tests sequentially..."
    echo "This will take approximately 9-10 minutes."
    echo ""
    
    for test in sync seqwrite seqread randread randwrite randrw latency mixed; do
      "$0" "$test" "$TARGET"
      sleep 2
    done
    
    echo "=========================================="
    echo "ALL TESTS COMPLETED"
    echo "=========================================="
    ;;

  *)
    echo "Unknown test type: $TEST"
    echo "Available tests:"
    echo "  sync       - Synchronous 4K writes with fdatasync"
    echo "  seqwrite   - Sequential 1M writes"
    echo "  seqread    - Sequential 1M reads"
    echo "  randread   - Random 4K reads"
    echo "  randwrite  - Random 4K writes"
    echo "  randrw     - Random 4K mixed (70% read, 30% write)"
    echo "  latency    - Low queue depth latency test"
    echo "  mixed      - Database-like mixed workload"
    echo "  all        - Run all tests sequentially"
    exit 1
    ;;
esac
