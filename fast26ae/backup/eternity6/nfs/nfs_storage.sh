#!/bin/bash
sudo mkfs.ext4 /dev/nvme0n1
sudo mount /dev/nvme0n1 /mnt/fast26ae
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
