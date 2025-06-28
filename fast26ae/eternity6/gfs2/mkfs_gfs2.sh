#!/bin/bash
sudo mkfs.gfs2 -p lock_dlm -t ptycluster:ptygfs2 -j 5 /dev/nvme0n1
