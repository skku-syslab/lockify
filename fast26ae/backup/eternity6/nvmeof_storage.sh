#!/bin/bash
modprobe nvme
modprobe nvme_rdma
modprobe nvme_core
modprobe nvme_fabrics
modprobe nvmet
modprobe nvmet_rdma
modprobe rdma_cm
modprobe ib_iser
modprobe ib_core
modprobe ib_ipoib
modprobe iw_cm
modprobe ib_uverbs
modprobe rdma_ucm
modprobe mlx5_ib
modprobe ib_cm

cd /sys/kernel/config/nvmet/subsystems/
mkdir pty
cd pty
echo 1 > attr_allow_any_host
mkdir namespaces/1
cd namespaces/1
echo -n /dev/nvme0n1 > device_path
echo 1 > enable
cd /sys/kernel/config/nvmet/ports/
mkdir 50000
cd 50000
echo 10.0.0.6 > addr_traddr
echo tcp > addr_trtype
echo 4420 > addr_trsvcid
echo ipv4 > addr_adrfam
ln -s /sys/kernel/config/nvmet/subsystems/pty /sys/kernel/config/nvmet/ports/50000/subsystems/pty
