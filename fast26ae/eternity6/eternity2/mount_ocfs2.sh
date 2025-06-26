#!/bin/bash
umount /mnt/fast26ae || true
systemctl restart o2cb
nvme disconnect -n pty
nvme connect -a 10.0.0.6 -t tcp -s 4420 -n pty
mount -t ocfs2 /dev/nvme1n1 /mnt/fast26ae
