#!/bin/bash

TEST_DIR="/mnt/fast26ae/ior_test"
TRANSFER_SIZE="4k"
BLOCK_SIZE="1g"
NPROCS=1
ITERATIONS=1

sudo mkdir -p $TEST_DIR
sudo chown -R fast26ae:fast26ae $TEST_DIR
sudo chmod 777 $TEST_DIR

sudo bash -c "echo 3 > /proc/sys/vm/drop_caches"

mpirun -np $NPROCS ../src/ior \
    -w \
    -t $TRANSFER_SIZE \
    -b $BLOCK_SIZE \
    -o $TEST_DIR/testfile_seq \
    -i $ITERATIONS \
    -C \
    -e \
    -k \
    -F

sudo bash -c "echo 3 > /proc/sys/vm/drop_caches"

mpirun -np $NPROCS ../src/ior \
    -r \
    -t $TRANSFER_SIZE \
    -b $BLOCK_SIZE \
    -o $TEST_DIR/testfile_seq \
    -i $ITERATIONS \
    -C \
    -e \
    -F

rm -f $TEST_DIR/testfile_seq.*

sudo bash -c "echo 3 > /proc/sys/vm/drop_caches"

mpirun -np $NPROCS ../src/ior \
    -w \
    -t $TRANSFER_SIZE \
    -b $BLOCK_SIZE \
    -o $TEST_DIR/testfile_random \
    -i $ITERATIONS \
    -C \
    -e \
    -z \
    -k \
    -F

sudo bash -c "echo 3 > /proc/sys/vm/drop_caches"

mpirun -np $NPROCS ../src/ior \
    -r \
    -t $TRANSFER_SIZE \
    -b $BLOCK_SIZE \
    -o $TEST_DIR/testfile_random \
    -i $ITERATIONS \
    -C \
    -e \
    -z \
    -F

rm -f $TEST_DIR/testfile_random.*
