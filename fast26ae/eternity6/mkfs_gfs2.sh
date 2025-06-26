#!/bin/bash
sudo mkfs.gfs2 -p lock_dlm -t ptycluster:ptygfs2 -j 5 /dev/nvme0n1
mount -t gfs2 /dev/nvme0n1 /mnt/fast26ae
