#!/bin/bash
echo 0 > /proc/sys/kernel/randomize_va_space
mkdir -p /mnt/fast26ae/filebench
sudo chmod -R 777 /mnt/fast26ae/filebench
sudo chown root:root /mnt/fast26ae/filebench
rm -rf /mnt/fast26ae/filebench/*
echo 3 > /proc/sys/vm/drop_caches
filebench -f ../workloads/fileserver.f


