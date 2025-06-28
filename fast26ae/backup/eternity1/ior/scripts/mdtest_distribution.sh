#!/bin/bash

TEST_DIR="/mnt/fast26ae/mdtest_dir"          # Directory where MDTest will perform operations
FILE_COUNT_PER_PROCESS=5000             # Number of files per process
TREE_DEPTH=2                            # Depth of directory tree
BRANCH_FACTOR=2                         # Number of directories per level
NPROCS=1                                # Number of processes
ITERATIONS=1                            # Number of iterations

sudo mkdir -p $TEST_DIR
sudo chown -R fast26ae:fast26ae /mnt/fast26ae

sudo bash -c "echo 3 > /proc/sys/vm/drop_caches"
sudo bash -c "echo 1 > /sys/kernel/debug/tracing/events/gfs2/gfs2_glock_lock_time/enable"
sudo bash -c "echo > /sys/kernel/debug/tracing/trace"

START_TIME=$(date +%s%N)
mpirun -np $NPROCS ../src/mdtest -i $ITERATIONS -I=$FILE_COUNT_PER_PROCESS -z $TREE_DEPTH -b $BRANCH_FACTOR -d $TEST_DIR -C
END_TIME=$(date +%s%N)

sudo bash -c "echo 0 > /sys/kernel/debug/tracing/events/gfs2/gfs2_glock_lock_time/enable"

ELAPSED_TIME=$((END_TIME - START_TIME))

sudo rm -rf $TEST_DIR
sudo python3 tdiff.py $ELAPSED_TIME
