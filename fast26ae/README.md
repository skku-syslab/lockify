# FAST'26 Artifact Evaluation Instructions

All artifact evaluation scripts have been fully prepared in this directory. **You do not need to refer to the `readme.md` file in the parent directory.**  

In our evaluation, we assume the following:

- There are **five client nodes**: `eternity1`, `eternity2`, `eternity5`, `eternity6`, and `eternity11`.
- All client nodes have the the Lockify kernel installed. ([Build Lockify Kernel](https://github.com/skku-syslab/lockify?tab=readme-ov-file#build-lockify-kernel))
- All client nodes have the required software packages installed. ([Configure shared-disk file systems](https://github.com/skku-syslab/lockify?tab=readme-ov-file#2-configure-shared-disk-file-system))
- The node `eternity6` hosts a shared storage device, `/dev/nvme0n1`, which is accessed by all five client nodes. Except for `eternity6` itself, the other four client nodes access this device via NVMe-over-TCP, where it appears locally as `/dev/nvme1n1`.

**Please adapt this configuration to match your testbed environment.**

## Hardware Configurations

Each client node is equipped with:

- Dual Intel Xeon Gold 5115 CPUs @ 2.40GHz (20 cores per socket, Hyper-Threading enabled)
- 64 GB RAM
- Ubuntu 18.04 with Linux kernel 6.6.23

All client nodes are connected via a 56 Gbps switch. A 250 GB Samsung 970 EVO Plus NVMe SSD is used for the shared storage.  
Unless noted otherwise, all nodes use default system settings.

## Preliminaries

**⚠️ [NOTE 1]**: Since client nodes access the shared storage under different device names (`/dev/nvme0n1` or `/dev/nvme1n1`) and use different sets of scripts, please use the node-specific scripts located in each node's directory. For example, if you're on `eternity1`, use the `~/eternity1/` directory:

```
cd ~/eternity1/
```

We use the notation `eternity[n]`, where `n` can be 1, 2, 5, 6, and 11.

**⚠️ [NOTE 2]**: Run all scripts in a root shell using `sudo -s`, **except** for `mdtest` (IOR).

<!--
All *eternity* nodes share the same home directory via NFS.  
To separate environments, individual directories are created for each node under the home directory:

```
~# ls
eternity1  eternity2  eternity5  eternity6  eternity11
```

From this point onward, please execute all node-specific scripts from their corresponding directories, for example:

```
~/eternity1/
~/eternity2/
...
```

> ⚠️ **Note**:  
> Since `sudo` privileges have been granted, perform all operations in a root shell using `sudo -s`,  
> **except** when running `mdtest` (IOR).
-->

Before starting the AE scripts, **each client node** should be correctly configured with their (1) target DLM kernel module, (2) NVMe-over-TCP setup, and (3) target file system.

### 1. Configure DLM kernel module

We provide three DLM kernel modules: `dlm`, `o2cb`, and `lockify`. These modules are mutually exclusive in the current setup, meaning that switching between DLM configurations requires reinstalling the desired module followed by a system reboot, which takes ~10 minutes. After reboot, the selected module is automatically loaded.

To configure the DLM module:

```
sudo -s
cd ~/eternity[n]/module/
```

Run the corresponding script for the target DLM module:

- `dlm`: `./dlm_compile.sh`
- `o2cb`: `./o2cb_compile.sh`
- `lockify`: `./lockify_compile.sh`

<!--
Each module directory includes its own compilation script:

- `module/dlm_compile.sh`
- `module/lockify_compile.sh`
- `module/o2cb_compile.sh`

To compile and apply a kernel module, run the corresponding script **as root**:

```
module/lockify_compile.sh
```

This script will:

1. Build the module  
2. Install it  
3. Reboot the node

After reboot, the module will be automatically loaded.

> ⚠️ **Note**:  
> This process may take 10 minutes or more depending on system load and build state.
> By default, the **lockify** module is already compiled and applied on the initial boot.
> This process must be performed on each node individually.
-->

### 2. Configure the shared storage (NVMe-over-TCP)

After each reboot, configure the shared storage using NVMe-over-TCP. The node `eternity6`, which hosts the shared storage device, must be configured first.

On `eternity6`:

```
sudo -s
cd ~/eternity6/
./nvmeof_storage.sh
```

On the other client nodes:

```
sudo -s
cd ~/eternity[n]/
./nvmeof.sh
```

### 3. Configure the shared-disk file system

We evaluate three file systems: **GFS2**, **OCFS2**, and **NFS**. The shared storage on `eternity6` is formatted with the target file system and mounted on all client nodes.

On `eternity6`:

```
sudo -s
cd ~/eternity6/
```

- **GFS2**: `./gfs2/mkfs_gfs2.sh`, `./gfs2/mount_gfs2.sh`
- **OCFS2**: `./ocfs2/mkfs_ocfs2.sh`, `./ocfs2/mount_ocfs2.sh`
- **NFS**: `./nfs/nfs_storage.sh`, `./nfs/nfs.sh`

On the other client nodes:

```
sudo -s
cd ~/eternity[n]/
```

- **GFS2**: `./gfs2/mount_gfs2.sh`
- **OCFS2**: `./ocfs2/mount_ocfs2.sh`
- **NFS**: `./nfs/nfs.sh`

### (Optional) 4. Verifying the file system

To verify that the file system is correctly shared:

1. On any node, create a file in the mounted directory:

    ```
    touch /mnt/fast26ae/testfile
    ```

2. On another node, verify that the file appears:

    ```
    ls /mnt/fast26ae
    ```

If the file is visible, the shared file system setup is successful.

> ⚠️ **Note**:  
> Before switching file systems (e.g., from GFS2 to OCFS2), make sure to unmount `/mnt/fast26ae` on all client nodes:

```
sudo -s
cd ~/eternity[n]/
```

- **GFS2**: `./gfs2/umount.sh`
- **OCFS2**: `./ocfs2/umount.sh`
- **NFS**: `./nfs/umount.sh`



<!--
We evaluate the following file systems:

- **GFS2** and **OCFS2**: These require shared storage.
- **NFS**: Uses file-level shared access via network.

---

### Shared NVMe Storage (for GFS2 and OCFS2)

The shared NVMe device is located on `eternity6`:

```
/dev/nvme0n1
```

To enable access from other nodes, we use **NVMe over TCP**.

#### Step 1: Export NVMe from eternity6

```
eternity6/nvmeof_storage.sh
```

#### Step 2: Connect from other nodes (eternity1, eternity2, eternity5, eternity11)

```
eternity[n]/nvmeof.sh
```

> ⚠️ **Note**:
> This must be repeated after **each reboot**.

#### Step 3: Create and Mount File System

For **GFS2**:

##### On `eternity6`, create the file system:

```
eternity6/gfs2/mkfs_gfs2.sh
```

> ⚠️ **Note**:  
> The `mkfs` process may ask for confirmation
> In such cases, please type `y` and press Enter.

##### On all nodes, mount the file system:

```
eternity[n]/gfs2/mount_gfs2.sh
```

For **OCFS2**:

##### On `eternity6`, create the file system:

```
eternity6/ocfs2/mkfs_ocfs2.sh
```

##### On all nodes, mount the file system:

```
eternity[n]/ocfs2/mount_ocfs2.sh
```

For **NFS**:

No NVMe setup is needed for NFS.

##### On `eternity6`, start the NFS server:

```
eternity6/nfs/nfs_storage.sh
```

##### Then, on the other nodes, mount the shared directory:

```
eternity[n]/nfs/nfs.sh
```

#### Verifying File System

To verify that the file system is correctly shared:

1. On any node, create a file in the mount directory:

    ```
    touch /mnt/fast26ae/testfile
    ```

2. On another node, check if the file appears:

    ```
    ls /mnt/fast26ae
    ```

If the file is visible, the setup is successful.

> ⚠️ **Note**:  
> Before switching file systems (e.g., from GFS2 to OCFS2), make sure to unmount `/mnt/fast26ae` on all nodes:

```
eternity[n]/[fs]/umount.sh
```

-->

## Lockify Evaluation

All experiments are configured to be executed from **eternity1**.  
Number of clients refers to the number of nodes that currently have the file system mounted.
For single-client benchmarks, ensure that **only eternity1** mounts the target file system (except for NFS, where eternity6 (the server) must also mount the directory for proper operation.)
If any part of the setup becomes inconsistent or misconfigured, the simplest and most reliable way to recover is to **reboot the nodes** and retry the setup step.

Benchmark scripts are located in the following directories:

```
eternity1/ior/scripts/
eternity1/postmark/
eternity1/filebench/scripts/
```

Check the benchmark results using the following metrics:

- IOR: Bandwidth in the Results section  
- mdtest: Directory/File creation in the SUMMARY rate section  
- Postmark: Transactions per second in the Time section  
- Filebench: ops/s in the IO Summary section

---

### Breakdown by Figure (from the paper)

---

> ⚠️ **Note**:
> To minimize kernel module patching overhead, we strongly recommend to avoid running experiments figure-by-figure.  
> Instead, group experiments by currently loaded kernel module, mounted file system, and number of client nodes and organize results incrementally in an Excel sheet during evaluation.

#### **Fig. 2**

- **Scripts**: `ior.sh` (a), `mdtest_create.sh` (b)  
- **Location**: `eternity1/ior/scripts/`  
- **File system**: GFS2  
- **Kernel module**: dlm  
- **Method**: Vary the number of client nodes that mount the GFS2 file system  
- `ior.sh` performs:  
  ```
  sequential write → sequential read → random write → random read
  ```

---

#### **Fig. 4**

- **Script**: `mdtest_distribution.sh`  
- **Location**: `eternity1/ior/scripts/`  
- **File system**: GFS2  
- **Kernel module**: dlm  
- **Method**: Mount GFS2 on varying numbers of client nodes, then execute the script.

---

#### **Fig. 5**

- **Script**: `mdtest_create.sh`  
- **Location**: `eternity1/ior/scripts/`  
- **File system**: OCFS2  
- **Kernel modules**: `o2cb`, `dlm`  
- **Method**:  
  Recompile the appropriate kernel module, mount OCFS2 on varying numbers of client nodes, and execute the script.

---

#### **Fig. 7**

- **Script**: `mdtest_create.sh`  
- **Location**: `eternity1/ior/scripts/`  
- **File systems**: NFS, GFS2, OCFS2  
- **Kernel modules**: `dlm`, `lockify`  
- **Method**:  
  - **NFS**: No kernel module changes are needed. Mount via NFS and run the script.  
  - **GFS2 / OCFS2**:  
    Recompile and load the appropriate kernel module (`dlm` or `lockify`), then vary the number of client nodes (1 to 5) and run the script.

---

#### **Fig. 8**

- **Script**: `mdtest_multi.sh`  
- **Location**: `eternity1/ior/scripts/`  
- **File systems**: NFS, GFS2, OCFS2  
- **Kernel modules**: `dlm`, `lockify`  
- **Method**: Same as Fig. 7

---

#### **Fig. 9**

- **Script**: `mdtest_distribution.sh`  
- **Location**: `eternity1/ior/scripts/`  
- **File system**: GFS2  
- **Kernel modules**: `dlm`, `lockify`  
- **Method**: Mount GFS2 on varying numbers of client nodes and execute the script.

---

#### **Fig. 10**

- **(a)**
  - **Script**: `postmark.sh`  
  - **Location**: `eternity1/postmark/`  
  - **File systems**: NFS, GFS2, OCFS2  
  - **Kernel modules**: `dlm`, `lockify`  

- **(b), (c)**
  - **Scripts**:  
    - `fileserver.sh` (b)  
    - `webproxy.sh` (c)  
  - **Location**: `eternity1/filebench/scripts/`  
  - **File systems**: NFS, GFS2, OCFS2  
  - **Kernel modules**: `dlm`, `lockify`  

---

> ⚠️ **Note**:  
> Benchmark results can vary, especially with **Filebench**.  
> For more consistent measurements, it is recommended to:
> - Reboot the system before execution
> - Run multiple trials and average results

## Contact

If you encounter any issues, please contact: **pty3595@g.skku.edu**
