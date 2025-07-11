#!/bin/bash

TEST_DIR="/mnt/fast26ae/mdtest_dir"		# Directory where MDTest will perform operations
FILE_COUNT_PER_PROCESS=5000		# Number of files per process
TREE_DEPTH=2				# Depth of directory tree
BRANCH_FACTOR=2				# Number of directories per level
NPROCS=1				# Number of processes
ITERATIONS=1				# Number of iterations

sudo bash -c "echo 3 > /proc/sys/vm/drop_caches"
sudo chown -R fast26ae:fast26ae /mnt/fast26ae
mkdir -p $TEST_DIR
mpirun -np $NPROCS ../src/mdtest -i $ITERATIONS -I=$FILE_COUNT_PER_PROCESS -z $TREE_DEPTH -b $BRANCH_FACTOR -d $TEST_DIR -C 
sudo rm -rf $TEST_DIR
