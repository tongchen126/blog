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
  echo "Usage: $0 [sync|seqwrite|seqread|randrw|randread|randwrite] [targetpath]"
  exit 1
fi

echo "=========================================="
echo "Running FIO test type: $TEST"
echo "Target path: $TARGET"
echo "=========================================="

case "$TEST" in
  sync)
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
    ;;

  seqwrite)
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
    ;;

  seqread)
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
    ;;

  randrw)
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
    ;;

  randread)
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
    ;;

  randwrite)
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
    ;;

  *)
    echo "Unknown test type: $TEST"
    echo "Available: sync, seqwrite, seqread, randrw, randread, randwrite"
    exit 1
    ;;
esac

echo "=========================================="
echo "Test '$TEST' completed."
echo "=========================================="
