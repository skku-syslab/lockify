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

nvme connect -a 10.0.0.6 -t tcp -s 4420 -n pty
