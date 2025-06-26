#!/bin/bash
umount /mnt/fast26ae || true
nvme disconnect -n pty
nvme connect -a 10.0.0.6 -t tcp -s 4420 -n pty
mount -t gfs2 /dev/nvme1n1 /mnt/fast26ae
