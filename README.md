# Lockify  
[USENIX FAST 2026] **Lockify: Understanding Linux Distributed Lock Management Overheads in Shared Storage**

---

**Lockify** is a novel distributed lock manager (DLM) for shared-disk file systems that reduces lock acquisition latency in the Linux kernel.  
It avoids unnecessary remote communication through **self-owner notifications** and **asynchronous ownership management**.

Implemented as a patch to the Linux kernel and evaluated on **GFS2** and **OCFS2**, Lockify achieves up to **6.4× higher throughput** than the default DLM, even under low-contention workloads.

---

## Repository Overview

This repository includes only the modified components of the Linux kernel:

- `fs/`: Contains Lockify implementation (`dlm/`) and small modifications to `gfs2/`, `ocfs2/` to support Lockify
- `include/`: Contains small changes to header files
- `fast26ae/`: Includes the README and scripts used for artifact evaluation (see `fast26ae/README.md`)

> **Note**: If you are reviewing the artifact for AE, all setup steps are already scripted — you can go directly to `fast26ae/README.md`.
---

## Getting Started Guide

This guide consists of three parts:

1. **Build the Lockify Kernel**  
   Compile the Linux kernel with Lockify modifications

2. **Set Up Remote Storage and File Systems**  
   Configure shared storage via NVMe-over-TCP and prepare GFS2/OCFS2

3. **Run Benchmarks**  
   Install benchmarking tools and run experiments across multiple nodes

---

## Build Lockify Kernel

This repository includes only the modified components. To use Lockify, copy the provided source files into a clean **Linux 6.6.23** kernel tree.

### 1. Clone the Repository

Clone the Lockify repository into the current directory:

```bash
git clone https://github.com/skku-syslab/lockify.git
```

### 2. Download and Prepare the Kernel

Download and extract the Linux 6.6.23 source:

```bash
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.6.23.tar.xz
tar -xf linux-6.6.23.tar.xz
cd linux-6.6.23
```

Copy the Lockify source files into the kernel source tree (assuming `lockify/` is in the same parent directory):

```bash
cp -r ../lockify/fs ./fs
cp -r ../lockify/include/* ./include
```

Ensure the following kernel config options are enabled:

```bash
make olddefconfig
make menuconfig
```

- `CONFIG_NVME_TARGET_TCP`
- `CONFIG_NVME_TCP`

Build and install:

```bash
make -j`nproc` bzImage
make -j`nproc` modules
make INSTALL_MOD_STRIP=1 modules_install
make install
```

Update GRUB :

```bash
sudo vi /etc/default/grub      # Make sure the new kernel is set as default
sudo update-grub
reboot
```

---

## Setup Remote Storage Devices and File System

To evaluate Lockify, configure a shared-disk setup across nodes.

- **For GFS2**:  
  - Edit `/etc/corosync/corosync.conf` consistently across nodes  
  - When formatting: `mkfs.gfs2 -p lock_dlm -t <clustername>:<fsname> ...`

- **For OCFS2**:  
  - Edit `/etc/ocfs2/cluster.conf`  
  - When formatting: `mkfs.ocfs2 --cluster-name <name> ...`

- **For NFS** :  
  - Configure `/etc/exports` on the nfs-server

### Configure NVMe-over-TCP

#### On the storage target node

> Replace values like `pty`, `/dev/nvme0n1`, and `10.0.0.6` with your actual device and IP.

```bash
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
```

#### On each client node

Install `nvme-cli`:  
https://github.com/linux-nvme/nvme-cli

Then connect:

```bash
nvme connect -a 10.0.0.6 -t tcp -s 4420 -n pty
```

---

## Run Benchmarks

Install the following benchmarking tools:

- **mdtest (via IOR)**  
  https://github.com/hpc/ior

- **Postmark**  
  ```bash
  sudo apt install postmark
  ```

- **Filebench**  
  https://github.com/filebench/filebench

Follow the installation instructions in each repository.  
Run benchmarks while varying the number of client nodes that mount the shared file system.

### Toy example: Running mdtest

Here is a sample script we used to run mdtest on a mounted file system:

```bash
#!/bin/bash

TEST_DIR="/path/to/mdtest_dir"            # Directory where MDTest will perform operations
FILE_COUNT_PER_PROCESS=5000               # Number of files per process
TREE_DEPTH=2                              # Depth of directory tree
BRANCH_FACTOR=2                           # Number of directories per level
NPROCS=1                                  # Number of processes
ITERATIONS=1                              # Number of iterations

# Clear page cache
sudo bash -c "echo 3 > /proc/sys/vm/drop_caches"

mkdir -p $TEST_DIR

# Run mdtest (assumes mdtest binary is in ./src/)
mpirun -np $NPROCS ./src/mdtest -i $ITERATIONS -I=$FILE_COUNT_PER_PROCESS -z $TREE_DEPTH -b $BRANCH_FACTOR -d $TEST_DIR -C
```

> 📌 Make sure to modify paths (`/path/to/mdtest_dir`, `./src/mdtest`) according to your environment.
---

## Authors

- **Taeyoung Park** (Sungkyunkwan University) — <pty3595@g.skku.edu>  
- **Yunjae Jo** (Sungkyunkwan University) — <jack3319@g.skku.edu>  
- **Daegyu Han** (Sungkyunkwan University) — <hdg9400@skku.edu>  
- **Beomseok Nam** (Sungkyunkwan University) — <bnam@skku.edu>  
- **Jaehyun Hwang** (Sungkyunkwan University) — <jh.hwang@skku.edu>

---

## GitHub Repository

For more information and updates, please visit the official repository:

🔗 https://github.com/skku-syslab/lockify
