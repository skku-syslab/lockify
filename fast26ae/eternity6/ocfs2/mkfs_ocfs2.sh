#!/bin/bash
umount /mnt/fast26ae || true
modprobe ocfs2
sudo systemctl restart o2cb
sudo systemctl restart ocfs2
sudo mkfs.ocfs2 --cluster-name=ptycluster --cluster-stack=o2cb /dev/nvme0n1
